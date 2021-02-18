/**
 * Namespace for components that are shared across views.
 */
const IDEALS = {

    /**
     * Application-wide fade time, for consistency.
     */
    FADE_TIME: 200,

    /**
     * High-level client for interacting with IDEALS.
     *
     * @constructor
     */
    Client: function() {

        const ROOT_URL   = $("input[name=root_url]").val();
        const CSRF_TOKEN = $("input[name=authenticity_token]").val();

        /**
         * Sends an HTTP DELETE request to the given URI.
         *
         * @param uri {String}
         * @param onSuccess {Function}
         * @param onError {Function}
         */
        this.delete = function (uri, onSuccess, onError) {
            $.ajax({
                type: "DELETE",
                url: uri,
                headers: { "X-CSRF-Token": CSRF_TOKEN },
                success: onSuccess,
                error: onError
            });
        };

        /**
         * @param unitID {Number}
         * @param onSuccess {Function} Function accepting response data.
         */
        this.fetchUnitCollections = function(unitID, onSuccess) {
            $.ajax({
                method: "GET",
                url: ROOT_URL + "/units/" + unitID + "/collections?for-select=true",
                headers: { "X-CSRF-Token": CSRF_TOKEN },
                success: onSuccess
            });
        };

        /**
         * @param query {String}
         * @param onSuccess {Function} Function accepting response data.
         * @return
         */
        this.fetchUsers = function(query, onSuccess) {
            const MAX_RESULTS = 8;
            $.ajax({
                url: ROOT_URL + "/users.json?window=" + MAX_RESULTS + "&q=" + query,
                method: "get",
                success: function(data, status, xhr) {
                    if (onSuccess) {
                        onSuccess(data, status, xhr);
                    }
                }
            });
        };

        /**
         * Sends an message to Medusa to ingest a file that exists in staging.
         *
         * @param uri [String]         Bitstream URI.
         * @param onSuccess {Function} Function accepting a string argument.
         *                             The string is the URI of the created
         *                             bitstream.
         * @param onError {Function}   Function accepting an {XMLHttpRequest}
         *                             argument.
         */
        this.post = function(uri, onSuccess, onError) {
            $.ajax({
                type: "POST",
                url: uri,
                headers: { "X-CSRF-Token": CSRF_TOKEN },
                success: onSuccess,
                error: onError
            });
        };

        /**
         * Sends a file to the server, creating a new Bitstream attached to an
         * Item.
         *
         * @param file [File]                  File to upload.
         * @param uri [String]                 URI to POST the file to.
         * @param onProgressChanged {Function} Function accepting an event
         *                                     argument.
         * @param onSuccess {Function}         Function accepting a string
         *                                     argument. The string is the URI
         *                                     of the created bitstream.
         * @param onError {Function}           Function accepting an
         *                                     {XMLHttpRequest} argument.
         */
        this.uploadFile = function(file, uri, onProgressChanged, onSuccess, onError) {
            const xhr = new XMLHttpRequest();
            if (onProgressChanged) {
                xhr.upload.addEventListener("progress", onProgressChanged);
            }
            xhr.open("POST", uri, true);
            xhr.setRequestHeader("X-Filename", file.name);
            xhr.setRequestHeader("X-Content-Length", file.size);
            xhr.setRequestHeader("X-CSRF-Token", CSRF_TOKEN);
            xhr.send(file);

            xhr.onreadystatechange = function () {
                if (this.readyState === this.HEADERS_RECEIVED) {
                    if (xhr.status === 0 || (xhr.status >= 200 && xhr.status < 400)) {
                        if (onSuccess) {
                            onSuccess(xhr.getResponseHeader("Location"));
                        }
                    } else if (onError) {
                        onError(xhr);
                    }
                }
            };
        };
    },

    /**
     * Enables a "check-all" button that checks and unchecks all of a given set
     * of checkboxes.
     *
     * @param button {jQuery} "Check all" button element.
     * @param checkboxes {jQuery} Collection of checkboxes.
     * @constructor
     */
    CheckAllButton: function(button, checkboxes) {
        button.on('click', function() {
            const checked = ($(this).data('checked') === 'true');
            if (checked) {
                checkboxes.prop('checked', false);
                $(this).data('checked', 'false');
                $(this).html('<i class="far fa-check-square"></i> Check All');
            } else {
                checkboxes.prop('checked', true);
                $(this).data('checked', 'true');
                $(this).html('<i class="far fa-minus-square"></i> Uncheck All');
            }
        });
    },

    /**
     * Enables two select menus: one for selecting a unit, and a dependent menu
     * for selecting a collection within the unit.
     *
     * For this to work, there must be two select menus already present in the
     * DOM with the following names:
     *
     * 1. `unit_id`
     * 2. `collection_item_memberships[collection_id]`
     *
     * And also a `collection_item_memberships[primary]` radio.
     *
     * There must also be at least two hidden fields for each unit/collection
     * pair:
     *
     * 1. `initial_unit_ids[]`
     * 2. `initial_collection_ids[]`
     *
     * @constructor
     */
    CollectionSelectMenus: function() {
        /**
         * @param unitMenu {jQuery} unit select menu or unit ID.
         * @param onComplete Callback function.
         */
        const fetchCollectionsForUnit = function(unitMenu, onComplete) {
            let unitID;
            if (typeof unitMenu === "string") {
                unitID   = unitMenu;
                unitMenu = $(".unit-menu").filter(function() { return this.value === unitID });
            } else {
                unitID = unitMenu.val();
            }
            new IDEALS.Client().fetchUnitCollections(unitID, function(data) {
                const collectionMenu = unitMenu.parents(".unit-collection-combo").find(".collection-menu");
                collectionMenu.children().remove();
                if (data.length > 0) {
                    $.each(data, function (index, value) {
                        collectionMenu.append(
                            "<option value='" + value[1] + "'>" + value[0] + "</option>");
                    });
                }
                if (onComplete) {
                    onComplete(collectionMenu);
                }
            });
        };

        const attachEventListeners = function() {
            $(".unit-menu").off("change").on("change", function() {
                fetchCollectionsForUnit($(this));
            });
            $(".add-collection").off("click").on("click", function() {
                // Clone the last unit/collection group.
                const lastCombo = $(".unit-collection-combo:last");
                const clone     = lastCombo.clone();
                // Insert the clone into the DOM.
                lastCombo.after(clone);
                lastCombo.after("<hr>");
                attachEventListeners();
                return false;
            });
            $(".remove-collection").off("click").on("click", function() {
                const combos = $(".unit-collection-combo");
                if (combos.length > 1) {
                    const lastCombo = combos.filter(":last");
                    lastCombo.prev("hr").remove();
                    lastCombo.remove();
                }
                return false;
            });
            const radios = $('.primary');
            radios.off("click").on("click", function() {
                radios.prop("checked", false);
                $(this).prop("checked", true);
            });
        };

        // Restore initial unit & collection selections.
        const initialUnitSelections       = $("[name='initial_unit_ids[]']");
        const initialCollectionSelections = $("[name='initial_collection_ids[]']");
        for (let i = 0; i < initialUnitSelections.length; i++) {
            const unitID = initialUnitSelections.eq(i).val();
            fetchCollectionsForUnit(unitID, function (collectionMenu) {
                collectionMenu.val(initialCollectionSelections.eq(i).val());
                collectionMenu.parents(".unit-collection-combo").find(".unit-menu").val(unitID);
            });
        }

        attachEventListeners();
    },

    /**
     * Enables a copy button that copies text to the clipboard.
     *
     * @param button {jQuery} Copy button element.
     * @param element {jQuery} Element whose text to copy.
     * @constructor
     */
    CopyButton: function(button, element) {
        // Filter out child nodes that may also contain text.
        element = element.contents().filter(function () {
            return this.nodeType === 3;
        }).first();
        let cancelled = false;
        button.on('click', function() {
            if (cancelled) {
                return;
            }
            cancelled = true;
            const temp = $("<input>");
            $("body").append(temp);
            temp.val(element.text()).select();
            document.execCommand("copy");
            temp.remove();

            let copied = $(" <strong><span class=\"text-success\">&check; Copied!</span></strong>");
            button.after(copied);
            setTimeout(function() {
                copied.fadeOut(400, function() {
                    cancelled = false;
                });
            }, 1500);
        });
    },

    /**
     * Enables the an expandable list of units generated by
     * {UnitsHelper#unit_list}.
     *
     * @constructor
     */
    ExpandableResourceList: function() {
        const ROOT_URL = $("input[name=root_url]").val();

        const setToggleState = function(elem, expanded) {
            const icon = expanded ? "fa-minus-square" : "fa-plus-square";
            elem.html("<i class=\"far " + icon + "\"></i>");
        };

        const insert = function(data, container) {
            if (data.length < 1) {
                return;
            }
            var html = "<ul>";
            $.each(data, function(index, obj) {
                html += "<li data-id=\"" + obj.id + "\">";
                if (obj.numCollections > 0 || obj.numChildren > 0) {
                    html += "<button class=\"btn btn-link expand\" type=\"button\" data-class=\"" + obj.class + "\">";
                    html +=   "<i class=\"far fa-plus-square\"></i>";
                    html += "</button>";
                }
                html +=   "<a href=\"" + obj.uri + "\">";
                html +=     (obj.class === "Unit") ?
                    "<i class=\"fa fa-university\"></i> " :
                    "<i class=\"far fa-folder-open\"></i> ";
                html +=     obj.title;
                html +=   "</a>";
                html += "</li>";
            });
            html += "</ul>";
            container.append(html);
            attachExpandButtonListeners();
        };

        const attachExpandButtonListeners = function() {
            $("button.expand").off("click").on("click", function () {
                const button = $(this);
                if (button.hasClass("expanded")) {
                    button.siblings("ul").remove();
                    setToggleState(button, false);
                    button.removeClass("expanded");
                } else {
                    button.addClass("expanded");
                    const id = button.parents("li").data("id");
                    setToggleState(button, true);
                    // Query for sub-units and sub-collections.
                    $.ajax({
                        method: "GET",
                        url: (button.data("class") === "Unit") ?
                            ROOT_URL + "/units/" + id + "/children" :
                            ROOT_URL + "/collections/" + id + "/children",
                        success: function (data, status, xhr) {
                            insert(data, button.parent());
                        }
                    });
                    if (button.data("class") === "Unit") {
                        // Query for collections that are immediate children of units.
                        $.ajax({
                            method: "GET",
                            url: ROOT_URL + "/units/" + id + "/collections",
                            success: function (data, status, xhr) {
                                insert(data, button.parent());
                            }
                        });
                    }
                }
            });
        };
        attachExpandButtonListeners();
    },

    FacetSet: function() {
        /**
         * Enables the facets returned by one of the facets_as_x() helpers.
         */
        this.init = function() {
            $("[name='fq[]']").off().on("change", function () {
                if ($(this).prop("checked")) {
                    window.location = $(this).data("checked-href");
                } else {
                    window.location = $(this).data("unchecked-href");
                }
            });
        }
    },

    /**
     * Manages the file-upload feature. This  consists of a table displaying
     * all of an item's bitstreams along with remove buttons for each, as well
     * as a drop zone for uploading files which, once uploaded, appear in the
     * table.
     *
     * The file upload feature is used in both public submission view and
     * private edit-item view.
     *
     * To simplify the implementation, we try to reject uploads of directories.
     *
     * @constructor
     */
    ItemFileUploader: function() {
        const DISALLOWED_LC_FILENAMES = new Set(); // lowercase for easy checking
        DISALLOWED_LC_FILENAMES.add(".ds_store");
        DISALLOWED_LC_FILENAMES.add("thumbs.db");

        const filesForm       = $("#files-form");
        const filesTable      = filesForm.find("table.files");
        let numUploadingFiles = 0;
        let numUploadedFiles  = filesTable.find("tr").length;

        /**
         * Adds a file to the table and uploads it to staging. If a file with
         * the same name already exists in the table, the upload is cancelled
         * and an alert is shown.
         *
         * @param file {File}
         */
        const addFile = function(file) {
            // Reject empty files
            if (file.size < 1) {
                return;
            }
            // If the file's name is disallowed
            if (DISALLOWED_LC_FILENAMES.has(file.name.toLowerCase())) {
                return;
            }
            // If a file with the same name has already been added
            if (getFilenames().has(file.name)) {
                alert("A file named " + file.name +
                    " has already been uploaded. Please rename it and try again.");
                return;
            }
            // All clear.
            // N.B.: This structure must be kept in sync with the structure in
            // the view template (deposit_files_form_uploads).
            filesTable.append("<tr data-filename='" + file.name + "'>" +
                "    <td></td>" +
                "    <td>" + file.name + "</td>" +
                "    <td>" + IDEALS.Util.formatBytes(file.size) + "</td>" +
                "    <td>" +
                "        <div class='progress'>" +
                "            <div class='progress-bar' role='progressbar' " +
                "                 style='width: 0' aria-valuenow='0'" +
                "                 aria-valuemin='0' aria-valuemax='100'></div>" +
                "        </div>" +
                "    </td>" +
                "    <td></td>" + // ingest button (admin only)
                "    <td></td>" + // remove button
                "</tr>");
            uploadFile(file);
        };

        /**
         * @returns {Set<String>}
         */
        const getFilenames = function() {
            const filenames = new Set();
            filesTable.find("tr").each(function() {
                filenames.add($(this).data("filename"));
            });
            return filenames;
        };

        /**
         * To be called when a file upload is complete.
         *
         * @param row {jQuery}
         * @param bitstreamURI {String}
         */
        const markRowUploadToStagingComplete = function(row, bitstreamURI) {
            row.data("uri", bitstreamURI);
            row.find("td:first-child").html("<i class='fa fa-check text-success'></i>");
            row.find(".progress").remove();

            // "Ingest Into Medusa" button (only available to admins)
            if (window.location.pathname.match(/^\/items\/\d+/)) {
                const ingestCell = row.find("td:nth-child(5)");
                ingestCell.html(
                    "<button class='btn btn-sm btn-light ingest' type='button'>" +
                    "   <i class='fa fa-upload'></i> Ingest Into Medusa" +
                    "</button>");
                ingestCell.find("button.ingest").on("click", function () {
                    onIngestFileButtonClicked($(this));
                });
            }
            // "Remove" button
            const removalCell = row.find("td:last-child");
            removalCell.html(
                "<button class='btn btn-sm btn-danger remove' type='button'>" +
                "   <i class='fa fa-minus'></i> Remove" +
                "</button>");
            removalCell.find("button.remove").on("click", function() {
                onRemoveFileButtonClicked($(this));
            });
        };

        /**
         * To be called when a file upload fails.
         *
         * @param row {jQuery}
         */
        const markRowUploadToStagingFailed = function(row) {
            row.find("td:first-child").html("<i class='fa fa-times text-danger'></i>");
            row.find(".progress").remove();

            // "Ingest Into Medusa" button (only available to admins)
            if (window.location.pathname.match(/^\/items\/\d+/)) {
                const ingestCell = row.find("td:nth-child(5)");
                ingestCell.html(
                    "<button class='btn btn-sm btn-light ingest' type='button'>" +
                    "   <i class='fa fa-upload'></i> Ingest Into Medusa" +
                    "</button>");
                ingestCell.find("button.ingest").on("click", function () {
                    onIngestFileButtonClicked($(this));
                });
            }
            // "Remove" button
            const removalCell = row.find("td:last-child");
            removalCell.html(
                "<button class='btn btn-sm btn-danger remove' type='button'>" +
                "   <i class='fa fa-minus'></i> Remove" +
                "</button>");
            removalCell.find("button.remove").on("click", function() {
                onRemoveFileButtonClicked($(this));
            });
        };

        /**
         * @returns {number}
         */
        this.numUploadedFiles = function() {
            return numUploadedFiles;
        };

        /**
         * @returns {number}
         */
        this.numUploadingFiles = function() {
            return numUploadingFiles;
        };

        /**
         * Ingests a file into Medusa.
         *
         * @param button {jQuery}
         */
        const onIngestFileButtonClicked = function(button) {
            const row          = button.parents("tr");
            const bitstreamURI = row.data("uri") + "/ingest";
            const onSuccess    = function() {
                button.fadeOut(IDEALS.FADE_TIME, function() {
                    button.parent().html("<span class='text-success'>" +
                        "<i class='fa fa-check'></i> Message Sent</span>");
                    row.find("button.remove").remove();
                    button.remove();
                });
            };
            const onError      = function(xhr, status, error) {
                console.error(xhr);
                console.error(status);
                console.error(error);
                alert("There was an error ingesting the file. If this error " +
                    "persists, please contact IDEALS staff.");
            };
            new IDEALS.Client().post(bitstreamURI, onSuccess, onError);
        };

        /**
         * Removes a file from staging.
         *
         * @param button {jQuery}
         */
        const onRemoveFileButtonClicked = function(button) {
            const row          = button.parents("tr");
            const bitstreamURI = row.data("uri");
            const onSuccess    = function() {
                row.fadeOut(IDEALS.FADE_TIME, function() {
                    row.remove();
                    numUploadedFiles--;
                });
            };
            const onError      = function(xhr, status, error) {
                console.error(xhr);
                console.error(status);
                console.error(error);
                alert("There was an error removing the file. If this error " +
                    "persists, please contact IDEALS staff.");
            };
            new IDEALS.Client().delete(bitstreamURI, onSuccess, onError);
        };

        const uploadFile = function(file) {
            const fileRow     = filesTable.find("tr[data-filename='" + file.name + "']");
            const progressBar = fileRow.find(".progress-bar");
            numUploadingFiles++;

            const onProgressChanged = function(e) {
                const complete = Math.round(e.loaded / e.total * 100);
                progressBar.attr("aria-valuenow", complete);
                progressBar.css("width", complete + "%");
            };
            const onComplete = function(bitstreamURI) {
                numUploadingFiles--;
                numUploadedFiles++;
                markRowUploadToStagingComplete(fileRow, bitstreamURI);
            };
            const onError = function(xhr) {
                numUploadingFiles--;
                markRowUploadToStagingFailed(fileRow);
            };
            new IDEALS.Client().uploadFile(file,
                $("input[name=item_bitstreams_uri]").val(),
                onProgressChanged, onComplete, onError);
        };

        filesTable.find("button.ingest").on("click", function(e) {
            e.preventDefault();
            onIngestFileButtonClicked($(this));
        });
        filesTable.find("button.remove").on("click", function(e) {
            e.preventDefault();
            onRemoveFileButtonClicked($(this));
        });

        // The file chooser is a file input, hidden via CSS, that is virtually
        // clicked when the drop zone is clicked in order to open a file
        // selection dialog.
        const fileChooser = $("#file-chooser");
        fileChooser.on("change", function() {
            const files = this.files;
            for (let i = 0; i < files.length; i++) {
                addFile(files[i]);
            }
        });

        const dropZone = $("#file-drop-zone");
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
            if (e.dataTransfer.items) {
                for (let i = 0; i < e.dataTransfer.items.length; i++) {
                    const item = e.dataTransfer.items[i];
                    // We want to distinguish between files and directories
                    // and ignore the directories. One would think that
                    // checking the `kind` property here would be all that is
                    // needed, but one would be forgetting that this is cross-
                    // browser JavaScript we are dealing with.
                    if (item.kind === "file") {
                        // So we utilize a weird technique by which we employ a
                        // FileReader to try to read the file. If it's a
                        // directory, FileReader should conk out somehow. But
                        // again, this is cross-browser JavaScript, so maybe it
                        // won't.
                        const file   = item.getAsFile();
                        const reader = new FileReader();
                        reader.onload = function(e) {
                            // It's probably a file. At least, we tried.
                            addFile(file);
                        };
                        reader.onerror = function(e) {
                            // It's a directory or something else happened that
                            // we can't recover from.
                        };
                        reader.readAsBinaryString(file);
                    }
                }
            } else {
                for (let i = 0; i < e.dataTransfer.files.length; i++) {
                    const file = e.dataTransfer.files[i];
                    addFile(file);
                }
            }
        });

    },

    MetadataEditor: function() {
        $("button.add").on("click", function(e) {
            const last_tr = $(this).parent(".form-group").find("table.metadata > tbody > tr:last-child");
            const clone = last_tr.clone();
            clone.find("input").val("");
            last_tr.after(clone);
            updateEventListeners();
            e.preventDefault();
        });
        updateEventListeners();

        function updateEventListeners() {
            $("button.remove").off("click").on("click", function () {
                if ($(this).parents("table").find("tr").length > 1) {
                    $(this).parents("tr").remove();
                }
            });
        }
    },

    /**
     * Supports "multi-element lists" (for want of a better term) in forms.
     * These are lists that support a model's one-to-many property where there
     * is one element per property, a remove button next to each element, and
     * an add button after the last element.
     *
     * @constructor
     */
    MultiElementList: function(minElements = 1) {
        $("button.add").on("click", function(e) {
            const clone = $(this).prev().clone();
            clone.find("input").val("");
            clone.find("select").attr("disabled", false);
            clone.removeClass("d-none");
            $(this).before(clone);
            updateEventListeners();
            if (clone.hasClass("user")) {
                new IDEALS.UserAutocompleter(clone.find("input"));
            }
            e.preventDefault();
        });
        updateEventListeners();

        function updateEventListeners() {
            $("button.remove").off("click").on("click", function () {
                const numIGs = $(this).parents(".form-group").find(".input-group").length;
                if (numIGs > minElements) {
                    const parentIG = $(this).parents(".input-group");
                    // Don't remove the last one, as the add button needs to
                    // clone it.
                    if (numIGs > 1) {
                        parentIG.remove();
                    } else {
                        parentIG.addClass("d-none");
                        parentIG.find("select").attr("disabled", true);
                    }
                }
            });
        }
    },

    NonNetIDLoginForm: function() {
        const ROOT_URL = $("input[name=root_url]").val();
        const modal    = $("#non-netid-login-modal");
        const flash    = modal.find(".alert");
        modal.find("button[type=submit]").on("click", function(event) {
            event.preventDefault();
            $.ajax({
                method: "POST",
                url: ROOT_URL + "/auth/identity/callback",

                data: $(this).parents("form").serialize(),
                success: function() {
                    flash.text("Login succeeded. One moment...")
                        .removeClass("alert-danger")
                        .addClass("alert-success")
                        .show();
                    modal.on("hidden.bs.modal", function () {
                        location.reload();
                    });
                    setTimeout(function() {
                        modal.modal("hide");
                    }, 2000);
                },
                error: function(data, status, xhr) {
                    console.log(data);
                    console.log(status);
                    console.log(xhr);
                    flash.removeClass("alert-success")
                        .addClass("alert-danger")
                        .text("Login failed.")
                        .show();
                }
            });
        });
    },

    /**
     * @param textField {jQuery} Text field element.
     * @constructor
     */
    UserAutocompleter: function(textField) {
        textField.on("keyup", function() {
            const textField = $(this);
            const menu      = textField.parent().find(".dropdown-menu");
            const query     = textField.val();
            if (query.length < 1) {
                menu.hide();
                return;
            }
            menu.css("top", $(this).position().top + $(this).height() + 14 + "px");
            menu.css("left", "14px");

            new IDEALS.Client().fetchUsers(query, function(data) {
                if (data['numResults'] > 0) {
                    menu.empty();
                    data['results'].forEach(function(result) {
                        const menuItem = $("<div class=\"dropdown-item\"></div>");
                        // It's important that all menu items be unique
                        // across all users. For users that have a name, we
                        // append their email. For unnamed users, we include
                        // only their email.
                        if (result['name'].length > 0) {
                            menuItem.html(result['name'] +
                                " <small>(" + result['email'] + ")</small>");
                        } else {
                            menuItem.html(result['email']);
                        }
                        menu.append(menuItem);
                        menuItem.on("click", function() {
                            textField.val($(this).text());
                            menu.hide();
                        });
                    });
                    menu.show();
                } else {
                    menu.hide();
                }
            });
        });
    },

    Util: {

        /**
         * Converts a byte size integer (like 50000) into a string like
         * "50 KB." The output harmonizes with that of Rails'
         * `number_to_human_size()` method.
         *
         * @param bytes {Number} Byte size integer.
         */
        formatBytes: function(bytes) {
            const sizes = ["bytes", "KB", "MB", "GB", "TB"];
            if (bytes === 0) {
                return "0 bytes";
            }
            const i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
            return Math.round(bytes / Math.pow(1024, i), 2) + " " + sizes[i];
        }

    }
};

const ideals_ready = function () {

    new IDEALS.NonNetIDLoginForm();

    var showChar = 140;
    var ellipsestext = "...";
    var moretext = "more";
    var lesstext = "less";
    $('.more').each(function () {
        var content = $(this).html();

        if (content.length > showChar) {

            var c = content.substr(0, showChar);
            var h = content.substr(showChar, content.length - showChar);

            var html = c + '<span class="moreellipses">' + ellipsestext + '&nbsp;</span><span class="morecontent"><span>' + h + '</span>&nbsp;&nbsp;<a href="" class="morelink">' + moretext + '</a></span>';

            $(this).html(html);
        }

    });

    $(".morelink").click(function () {
        if ($(this).hasClass("less")) {
            $(this).removeClass("less");
            $(this).html(moretext);
        } else {
            $(this).addClass("less");
            $(this).html(lesstext);
        }
        $(this).parent().prev().toggle();
        $(this).prev().toggle();
        return false;
    });

    // Copy the URL "q" argument into the filter field, as the browser won't do
    // this automatically.
    const queryArgs = new URLSearchParams(location.search);
    if (queryArgs.has("q")) {
        $("input[name=q]").val(queryArgs.get("q"));
    }

    // Submit forms when a "sort" select menu changes.
    $("[name=sort]").on("change", function() {
        $(this).parents("form:first").submit();
    });
    /*
    // Save the last-selected tab in a cookie.
    $('a[data-toggle="tab"]').on('click', function(e) {
        Cookies.set('last_tab', $(e.target).attr('href'));
    });

    // Activate the cookie-stored tab, if it exists.
    const lastTab = Cookies.get('last_tab');
    if (lastTab) {
        $('a[href="' + lastTab + '"]').click();
    }*/

    // Don't allow disabled elements to be clicked.
    $("[disabled='disabled']").on("click", function() {
        return false;
    });
};
$(document).ready(ideals_ready);