/**
 * Handles list-imports view (/imports).
 *
 * @constructor
 */
const ImportsView = function() {

    const CSRF_TOKEN = $("meta[name=csrf-token]").attr("content");
    const ROOT_URL   = $("input[name=root_url]").val();

    const UploadPackagePanel = function() {
        console.debug("Initializing UploadPackagePanel");
        const dropZone    = $(".file-drop-zone");
        const waitMessage = $("#wait-message");

        /**
         * @param entry {FileSystemFileEntry}
         */
        function deleteAllFiles() {
            console.debug("deleteAllFiles()");
            $.ajax({
                method:  "POST",
                url:     $("input[name=import_uri]").val() + "/delete-all-files",
                headers: { "X-CSRF-Token": CSRF_TOKEN },
                success: function() {
                    console.debug("deleteAllFiles() succeeded");
                },
                error:   function(data, status, xhr) {
                    console.error(data);
                    dropZone.before(
                        '<div class="alert alert-danger">' +
                        'Failed to prepare the import for uploading.</div>');
                }
            });
        }

        /**
         * @param entry {FileSystemFileEntry}
         * @parma onUploadedCallback {Function}
         */
        function addFile(entry, onUploadedCallback) {
            console.debug("addFile(): " + entry.name);
            entry.file(function(file) {
                const uri = $("input[name=import_uri]").val() + "/upload-file";
                const xhr = new XMLHttpRequest();
                xhr.open("POST", uri, true);
                //xhr.upload.addEventListener("progress", function (e) {
                //    console.log("onUploadProgressChanged(): " +
                //        Math.round(e.loaded / e.total * 100));
                //});
                // For packages, this header value will be relative to the
                // package root, so we will have to trim off the package dir
                // itself. But we may also be dealing with individual files
                // that are not packages, like CSVs, for which this will simply
                // be the filename.
                let relativePath = entry.fullPath.split("/").slice(2).join("/");
                if (relativePath === "") { // root-level files
                    const parts  = entry.fullPath.split("/");
                    relativePath = parts[parts.length - 1];
                }
                xhr.setRequestHeader("X-Relative-Path", relativePath);
                xhr.setRequestHeader("X-CSRF-Token", CSRF_TOKEN);
                xhr.onloadend = onUploadedCallback;
                xhr.onerror   = function(e) { console.error(e); };
                console.debug("POST " + uri);
                xhr.send(file);
            }, function(e) {
                console.error(e);
            });
        }

        function completeUpload() {
            $.ajax({
                method:  "PUT",
                url:     $("input[name=import_uri]").val(),
                headers: { "X-CSRF-Token": CSRF_TOKEN },
                success: function() {
                    console.debug("completeUpload() succeeded");
                    // the page is going to reload
                },
                error: function(data, status, xhr) {
                    console.error(data);
                    dropZone.before(
                        '<div class="alert alert-danger">Upload failed.</div>');
                }
            });
        }

        // The file chooser is a file input, hidden via CSS, that is virtually
        // clicked when the drop zone is clicked in order to open a file
        // selection dialog.
        const fileChooser = $(".file-chooser");
        fileChooser.on("change", function() {
            console.debug("File chooser changed");
            waitMessage.show();
            dropZone.hide();
            deleteAllFiles();
            const files = this.files;
            for (let i = 0; i < files.length; i++) {
                addFile(files[i]);
            }
        });

        dropZone.on("dragover", function(e) {
            e.preventDefault();
            e.originalEvent.dataTransfer.dropEffect = "copy";
        });
        dropZone.on("click", function(e) {
            e.preventDefault();
            fileChooser.click();
        });
        dropZone.on("drop", function(e) {
            e.preventDefault();
            e = e.originalEvent;
            waitMessage.show();
            dropZone.hide();
            deleteAllFiles();
            getAllFileEntries(e.dataTransfer.items).then(
                function(entries) {
                    var numAdded = 0;
                    entries.forEach(function(entry) {
                        addFile(entry, function() {
                            numAdded++;
                            if (numAdded >= entries.length) {
                                completeUpload();
                            }
                        });
                    });
                },
                function(error) {
                    console.error(error);
                });
        });

        async function getAllFileEntries(dataTransferItemList) {
            let fileEntries = [];
            let queue = [];
            for (let i = 0; i < dataTransferItemList.length; i++) {
                queue.push(dataTransferItemList[i].webkitGetAsEntry());
            }
            while (queue.length > 0) {
                let entry = queue.shift();
                if (entry.isFile) {
                    fileEntries.push(entry);
                } else if (entry.isDirectory) {
                    queue.push(...await readAllDirectoryEntries(entry.createReader()));
                }
            }
            return fileEntries;
        }

        // Get all the entries (files or sub-directories) in a directory
        // by calling readEntries until it returns an empty array.
        async function readAllDirectoryEntries(directoryReader) {
            let entries = [];
            let readEntries = await readEntriesPromise(directoryReader);
            while (readEntries.length > 0) {
                entries.push(...readEntries);
                readEntries = await readEntriesPromise(directoryReader);
            }
            return entries;
        }

        async function readEntriesPromise(directoryReader) {
            return await new Promise((resolve, reject) => {
                // N.B.: readEntries will return at most 100 items.
                directoryReader.readEntries(resolve, reject);
            });
        }
    };

    $("button.new-import").on("click", function() {
        const url = ROOT_URL + "/imports/new";
        $.get(url, function (data) {
            const body = $("#new-import-modal .modal-body");
            body.html(data);
            body.find("[name=unit_id]").on("change", function() {
                const unitID = $(this).val();
                new IDEALS.Client().fetchUnitCollections(unitID, function(data) {
                    const collectionMenu = body.find("[name='import[collection_id]']");
                    collectionMenu.children().remove();
                    if (data.length > 0) {
                        $.each(data, function (index, value) {
                            collectionMenu.append(
                                "<option value='" + value[1] + "'>" + value[0] + "</option>");
                        });
                    }
                });
            });
        });
    });

    function attachEventListeners() {
        $("button.edit-import").on("click", function() {
            const importID = $(this).data("import-id");
            const url      = ROOT_URL + "/imports/" + importID + "/edit";
            $.get(url, function (data) {
                $("#edit-import-modal .modal-body").html(data);
                new UploadPackagePanel();
            });
        });
        $("button.show-import").on("click", function() {
            const importID = $(this).data("import-id");
            const url      = ROOT_URL + "/imports/" + importID;
            $.get(url, function (data) {
                $("#show-import-modal .modal-body").html(data);
            });
        });
    }
    attachEventListeners();

    // Reload the imports table every 5 seconds
    setInterval(function() {
        $.ajax({
            url: ROOT_URL + "/imports",
            success: function(data) {
                // index.js.erb will take it from here
                attachEventListeners();
            },
            error: function(data, status, xhr) {
                console.error(data);
            }
        });
    }, 5000);
};

$(document).ready(function() {
    if ($("body#imports").length) {
        new ImportsView();
    }
});
