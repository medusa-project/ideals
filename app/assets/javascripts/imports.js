/**
 * Handles list-imports view (/imports).
 */
const ImportsView = {

    initialize: function() {
        const CSRF_TOKEN = $("meta[name=csrf-token]").attr("content");
        const ROOT_URL   = $("input[name=root_url]").val();

        const UploadPackagePanel = function() {
            console.debug("Initializing UploadPackagePanel");
            const panel        = $("#edit-import-modal");
            const waitMessage  = $("#wait-message");
            const fileInput    = panel.find("input[name=file]");
            const submitButton = panel.find("input[type=submit]");
            const importURI    = $("input[name=import_uri]").val();
            const xhr          = new XMLHttpRequest();

            const fetchUploadURI = function(file) {
                const jsonImportURI = importURI + ".json";
                console.debug("fetchUploadURI(): GET " + jsonImportURI);
                $.ajax({
                    url: jsonImportURI,
                    success: function(data) {
                        console.debug("fetchUploadURI(): successfully loaded " +
                            jsonImportURI);
                        uploadFile(file, data.upload_url);
                    }
                });
            };

            const uploadFile = function(file, uploadURI) {
                console.debug("uploadFile() invoked with " + file.name);
                const startTime = new Date().getTime();
                const formData  = new FormData();
                formData.append("file", file);

                xhr.open("PUT", uploadURI, true);
                xhr.upload.addEventListener("progress", function (e) {
                    const progressBar = $("#progress-bar");
                    const progress    = e.loaded / e.total * 100;
                    progressBar.attr("aria-valuenow", progress);
                    const pctString = progress.toFixed(1) + "%";
                    progressBar.children(":first").css("width", pctString);
                    progressBar.children(":first").text(pctString);

                    $("#uploaded-bytes").text(IDEALS.StringUtils.formatBytes(e.loaded, 1));
                    $("#total-bytes").text(IDEALS.StringUtils.formatBytes(e.total, 1));

                    const eta = IDEALS.TimeUtils.eta(
                        startTime, e.loaded / parseFloat(e.total));
                    const remaining = eta - new Date().getTime();
                    $("#eta").text(IDEALS.TimeUtils.timeToHMS(remaining) + " remaining");
                });
                xhr.setRequestHeader("X-CSRF-Token", CSRF_TOKEN);
                xhr.onloadstart = function() {
                    submitButton.prop("disabled", true);
                    fileInput.hide();
                    waitMessage.show();
                };
                xhr.onloadend = function() {
                    if (xhr.status === 200) {
                        const completeUploadURI = importURI + "/complete-upload";
                        console.debug("uploadFile(): upload complete");
                        console.debug("uploadFile(): POST " + completeUploadURI);
                        $.ajax({
                            method:  "POST",
                            url:     completeUploadURI,
                            headers: {"X-CSRF-Token": CSRF_TOKEN},
                            success: function() {
                                window.location.reload();
                            }
                        });
                    } else {
                        console.error("uploadFile(): received HTTP " + xhr.status + " for POST " + uploadURI);
                    }
                };
                xhr.onerror = function(e) {
                    console.error(e);
                };
                xhr.send(formData);
            };

            panel.on("hide.bs.modal", function() {
                xhr.abort();
            });
            submitButton.on("click", function() {
                const file = fileInput.prop("files")[0];
                console.debug("Submitted " + file.name + " (" + file.size + " bytes)");
                console.debug("PATCH " + importURI);
                // Update the import with the filename and length.
                $.ajax({
                    method:  "PATCH",
                    url:     importURI,
                    headers: {"X-CSRF-Token": CSRF_TOKEN},
                    data: {
                        import: {
                            filename: file.name,
                            length:   file.size
                        }
                    },
                    success: function() {
                        // Now there will be a presigned URL in the import's
                        // JSON representation.
                        fetchUploadURI(file);
                    }
                });
                return false;
            });
        };

        $("button.new-import").on("click", function () {
            const institutionID = $("input[name=institution_id]").val();
            const url           = ROOT_URL + "/imports/new?" +
                "import%5Binstitution_id%5D=" + institutionID;
            $.get(url, function (data) {
                const body = $("#new-import-modal .modal-body");
                body.html(data);
                body.find("[name=unit_id]").on("change", function () {
                    const unitID = $(this).val();
                    new IDEALS.Client().fetchUnitCollections(unitID, true, false, function (data) {
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
            $("button.edit-import").on("click", function () {
                const importID = $(this).data("import-id");
                const url = ROOT_URL + "/imports/" + importID + "/edit";
                $.get(url, function (data) {
                    $("#edit-import-modal .modal-body").html(data);
                    new UploadPackagePanel();
                });
            });
            $("button.show-import").on("click", function () {
                const importID = $(this).data("import-id");
                const url = ROOT_URL + "/imports/" + importID;
                $.get(url, function (data) {
                    $("#show-import-modal .modal-body").html(data);
                });
            });
        }

        attachEventListeners();

        // Reload the imports table every 5 seconds
        setInterval(function () {
            $.ajax({
                url: ROOT_URL + "/imports",
                success: function (data) {
                    // index.js.erb will take it from here
                    attachEventListeners();
                },
                error: function (data, status, xhr) {
                    console.error(data);
                }
            });
        }, 5000);
    }
};

$(document).ready(function() {
    if ($("body#imports").length) {
        ImportsView.initialize();
    }
});
