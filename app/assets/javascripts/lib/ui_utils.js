IDEALS.UIUtils = {};

/**
 * Application-wide fade time, for consistency.
 */
IDEALS.UIUtils.FADE_TIME = 200;

/**
 * Amount of time to wait after the last keyup before firing an XHR.
 */
IDEALS.UIUtils.KEY_DELAY = 1500;

/**
 * Amount of time to wait after the last keyup before firing an XHR.
 */
IDEALS.UIUtils.REFRESH_FREQUENCY = 5000;

/**
 * Renders a chart into a canvas using chart.js (https://www.chartjs.org).
 *
 * @param canvas {jQuery} Canvas element.
 * @param chart_data      Array of objects with `month` and `dl_count`
 *                        keys.
 * @param color           CSS color.
 * @constructor
 */
IDEALS.UIUtils.Chart = function(canvas, chart_data, color) {
    // X axis labels
    const labels = $.map(chart_data, function(n, i) {
        const regex   = /^(\d+)-(\d+)-(\d+)/;
        const matches = regex.exec(n.month);
        return matches[2] + "/" + matches[1];
    });
    // Values
    const values = $.map(chart_data, function(n, i) {
        return n.dl_count;
    });
    // Colors
    const colors = [];
    for (var i = 0; i < values.length; i++) {
        colors.push(color);
    }

    new Chart(canvas, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                data: values,
                backgroundColor: colors,
                borderColor: colors,
                borderWidth: 1
            }]
        },
        options: {
            plugins: {
                legend: {
                    display: false
                }
            },
            scale: {
                ticks: {
                    precision: 0
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    title: {
                        display: true,
                        text: "Downloads"
                    }
                }
            }
        }
    });
};

/**
 * Enables a "check-all" button that checks and unchecks all of a given set
 * of checkboxes.
 *
 * @param button {jQuery} "Check all" button element.
 * @param checkboxes {jQuery} Collection of checkboxes.
 * @constructor
 */
IDEALS.UIUtils.CheckAllButton = function(button, checkboxes) {
    button.on('click', function(e) {
        e.preventDefault();
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
};

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
IDEALS.UIUtils.CollectionSelectMenus = function() {
    /**
     * @param unitMenu {jQuery} unit select menu.
     * @param onComplete Callback function.
     */
    const fetchCollectionsForUnit = function(unitMenu, onComplete) {
        const unitID = unitMenu.val();
        new IDEALS.Client().fetchUnitCollections(unitID, true, false, function(data) {
            const collectionMenu = unitMenu.closest(".unit-collection-combo").find(".collection-menu");
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
            clone.find("input[type=radio]").prop("checked", false);
            const clonedUnitMenu = clone.find("select:first");
            clonedUnitMenu.find("option:first").prop("selected", true);
            fetchCollectionsForUnit(clonedUnitMenu);
            // Insert the clone into the DOM.
            lastCombo.after(clone);
            attachEventListeners();
            return false;
        });
        $(".remove-collection").off("click").on("click", function() {
            if ($(".unit-collection-combo").length > 1) {
                const parentCombo = $(this).closest(".unit-collection-combo");
                parentCombo.remove();
                if (parentCombo.find("input[type=radio]:checked").length) {
                    $(".unit-collection-combo:first input[type=radio]").prop("checked", true);
                }
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
        const unitID       = initialUnitSelections.eq(i).val();
        const unitMenu     = $(".unit-menu").filter(":eq(" + i + ")");
        const collectionID = initialCollectionSelections.eq(i).val();
        fetchCollectionsForUnit(unitMenu, function (collectionMenu) {
            collectionMenu.val(collectionID);
            collectionMenu.parents(".unit-collection-combo").find(".unit-menu").val(unitID);
        });
    }

    attachEventListeners();
};

IDEALS.UIUtils.ContactForm = function() {
    const ROOT_URL  = $("input[name=root_url]").val();
    const container = $("#contact-form");
    const form      = container.find("form");
    const alert     = container.find("#contact-form-alert");
    form.on("submit", function() {
        $.ajax({
            method:  "POST",
            url:     ROOT_URL + "/contact",
            data:    $(this).serialize(),
            success: function() {
                alert.text("Thanks for your feedback! If you requested " +
                    "a reply, we will get back to you as soon as we can.")
                    .removeClass("alert-danger")
                    .addClass("alert-success")
                    .show();
                form.children().remove();
            },
            error: function(data, status, xhr) {
                console.log(data);
                console.log(status);
                console.log(xhr);
                alert.removeClass("alert-success")
                    .addClass("alert-danger")
                    .text(data.responseText)
                    .show();
            }
        });
        return false;
    });
};

/**
 * Enables a copy button that copies text to the clipboard.
 *
 * @param button {jQuery} Copy button element.
 * @param element {jQuery} Element whose text to copy.
 * @constructor
 */
IDEALS.UIUtils.CopyButton = function(button, element) {
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

        let copied = $(" <span class=\"badge bg-success ms-1\">&check; COPIED</span>");
        button.after(copied);
        setTimeout(function() {
            copied.fadeOut(400, function() {
                cancelled = false;
            });
        }, 1500);
    });
};

/**
 * Given a date input with a year menu/field and month and day select
 * menus, ensures that the day menu always contains the correct number of
 * days depending on the month and (leap) year.
 *
 * @param yearField {jQuery} Text field or select menu.
 * @param monthMenu {jQuery} Select menu.
 * @param dayMenu {jQuery} Select menu.
 * @constructor
 */
IDEALS.UIUtils.DatePicker = function(yearField, monthMenu, dayMenu) {
    const dayCounts              = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    const monthMenuIncludesBlank = (monthMenu.find("option:first").val() === "")
    const onYearChanged = function() {
        const year  = parseInt(yearField.val());
        const month = parseInt(monthMenu.val());
        if (!isNaN(year) && month === 2) {
            if (year % 4 === 0) { // february has 29 days in leap years
                dayMenu.append("<option value='29'>29</option>");
            } else {
                dayMenu.find("option[value='29']").remove();
            }
        }
    };
    const onMonthChanged = function() {
        const year  = parseInt(yearField.val());
        const month = parseInt(monthMenu.val());
        if (!isNaN(month)) {
            const numDays          = dayCounts[month - 1];
            const numDaysInMenuNow = dayMenu.children().length - (monthMenuIncludesBlank ? 1 : 0);
            if (numDays > numDaysInMenuNow) {
                for (var i = numDaysInMenuNow; i < numDays; i++) {
                    dayMenu.append("<option>" + (i + 1)  + "</option>");
                }
            } else if (numDays < numDaysInMenuNow) {
                for (var i = 0; i < numDaysInMenuNow - numDays; i++) {
                    dayMenu.children().filter(":last").remove();
                }
            }
            if (month === 2 && year % 4 === 0) { // february has 29 days in leap years
                dayMenu.append("<option value='29'>29</option>");
            }
        }
    };
    monthMenu.on("change", onMonthChanged).trigger("change");
    yearField.on("change", onYearChanged);
};

/**
 * @param modal {jQuery}
 * @param html {String}
 * @constructor
 */
IDEALS.UIUtils.DownloadPanel = function(modal, html) {
    const modal_body = modal.find(".modal-body");
    modal_body.html(html);
    // Repeatedly check the download status, updating the modal
    // body HTML. Stop checking when the HTML contains a
    // `download_ready` input value of `true` or when the modal is
    // closed.
    const status_check_interval = setInterval(function() {
        const download_ready = modal_body.find("[name=download_ready]").val();
        if (download_ready !== "true") {
            const download_key = modal_body.find("[name=download_key]").val();
            const url          = "/downloads/" + download_key;
            $.get(url, function(data) {
                modal_body.html(data);
            });
        } else {
            clearInterval(status_check_interval);
        }
    }, 4000);
    modal.on("hide.bs.modal", function() {
        clearInterval(status_check_interval);
    });
};

/**
 * @param container {jQuery}
 * @constructor
 */
IDEALS.UIUtils.enablePopovers = function(container) {
    if (!container) {
        container = $(document);
    }
    const popoverTriggerList = container.find('[data-bs-toggle="popover"]')
    const popoverList = [...popoverTriggerList].map(popoverTriggerEl => new bootstrap.Popover(popoverTriggerEl))
};

/**
 * Enables the an expandable list of units generated by
 * {UnitsHelper#unit_list}.
 *
 * @constructor
 */
IDEALS.UIUtils.ExpandableResourceList = function() {
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
                "<i class=\"fa fa-building\"></i> " :
                "<i class=\"far fa-folder-open\"></i> ";
            html +=     obj.title;
            html +=   "</a>";
            html += "</li>";
        });
        html += "</ul>";
        // Ensure that units always appear before collections.
        if (data[0].class === "Unit") {
            container.find("a:first").after(html);
        } else {
            container.append(html);
        }
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
                        url: ROOT_URL + "/units/" + id + "/collections-tree-fragment",
                        success: function (data, status, xhr) {
                            insert(data, button.parent());
                        }
                    });
                }
            }
        });
    };
    attachExpandButtonListeners();
};

IDEALS.UIUtils.FacetSet = function() {
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
};

/**
 * Manages the file-upload feature. This consists of a table displaying
 * all of an item's bitstreams along with remove buttons for each, as well
 * as a drop zone for uploading files which, once uploaded, appear in the
 * table.
 *
 * The file upload feature is used in both public submission view and
 * private edit-item view.
 *
 * To simplify the implementation, we try to reject uploads of directories.
 *
 * N.B.: clients are advised to supply a error handler callback via
 * {onIOError()}. Otherwise, errors will be displayed in alerts.
 *
 * @constructor
 */
IDEALS.UIUtils.ItemFileUploader = function() {
    const DISALLOWED_LC_FILENAMES = new Set(); // lowercase for easy checking
    DISALLOWED_LC_FILENAMES.add(".ds_store");
    DISALLOWED_LC_FILENAMES.add("thumbs.db");

    const itemID     = $("[name=item_id]").val();
    const canDelete  = ($("[name=can_delete_bitstreams]").val() === "true");
    const filesForm  = $("#files-form");
    const filesTable = filesForm.find("table.files");
    const self       = this;

    let uploadInProgressCallback, uploadCompleteCallback, uploadErrorCallback,
        removeFileCompleteCallback, removeFileErrorCallback;

    this.numUploadingFiles = 0;
    this.numUploadedFiles  = filesTable.find("tr").length;

    /**
     * Adds a file to the table and uploads it to the server. If a file
     * with the same name already exists in the table, the upload is
     * cancelled and an alert is shown.
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
            const message = "A file named " + file.name +
                " has already been uploaded. Please rename it and try again."
            if (uploadErrorCallback) {
                uploadErrorCallback(file, message);
            } else {
                alert(message);
            }
            return;
        }
        // All clear.
        // N.B.: This structure must be kept in sync with the structure in
        // the view template (edit_files_form_uploads).
        filesTable.append("<tr data-filename=\"" + file.name.replace("\"", "&quot;") + "\">" +
            "    <td></td>" +
            "    <td>" + file.name + "</td>" +
            "    <td>" + IDEALS.StringUtils.formatBytes(file.size) + "</td>" +
            "    <td>" +
            "        <div class='progress'>" +
            "            <div class='progress-bar' role='progressbar' " +
            "                 style='width: 0' aria-valuenow='0'" +
            "                 aria-valuemin='0' aria-valuemax='100'></div>" +
            "        </div>" +
            "    </td>" +
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
     * Called when a file upload is complete.
     *
     * @param row {jQuery}
     * @param bitstreamURI {String}
     */
    const markRowUploadToStagingComplete = function(row, bitstreamURI) {
        row.data("uri", bitstreamURI);
        row.find("td:first-child").html("<i class='fa fa-check text-success'></i>");
        row.find(".progress").remove();

        // "Remove" button
        if (canDelete) {
            const removalCell = row.find("td:last-child");
            removalCell.html(
                "<button class='btn btn-sm btn-outline-danger remove' type='button'>" +
                "   <i class='fa fa-minus'></i> Remove" +
                "</button>");
            removalCell.find("button.remove").on("click", function () {
                onRemoveFileButtonClicked($(this));
            });
        }
    };

    this.onRemoveFileComplete = function(callback) {
        removeFileCompleteCallback = callback;
    };

    this.onRemoveFileError = function(callback) {
        removeFileErrorCallback = callback;
    };

    this.onUploadInProgress = function(callback) {
        uploadInProgressCallback = callback;
    };

    this.onUploadComplete = function(callback) {
        uploadCompleteCallback = callback;
    };

    this.onUploadError = function(callback) {
        uploadErrorCallback = callback;
    };

    /**
     * Removes a file from staging.
     *
     * @param button {jQuery}
     */
    const onRemoveFileButtonClicked = function(button) {
        const row          = button.parents("tr");
        const bitstreamURI = row.data("uri");
        const onSuccess = function () {
            row.fadeOut(IDEALS.UIUtils.FADE_TIME, function () {
                row.remove();
                self.numUploadedFiles--;
            });
            if (removeFileCompleteCallback) {
                removeFileCompleteCallback();
            }
        };
        const onError = function (xhr, status, error) {
            console.error(xhr);
            console.error(status);
            console.error(error);
            const message = "There was an error removing the file. " +
                "If this error persists, please contact us."
            if (removeFileErrorCallback) {
                removeFileErrorCallback(message);
            } else {
                alert(message);
            }
        };
        new IDEALS.Client().delete(bitstreamURI, onSuccess, onError);
    };

    const uploadFile = function(file) {
        const fileRow     = filesTable.find("tr[data-filename=\"" + file.name.replace("\"", "&quot;") + "\"]");
        const progressBar = fileRow.find(".progress-bar");
        self.numUploadingFiles++;

        const onProgressChanged = function(e) {
            const complete = Math.round(e.loaded / e.total * 100);
            progressBar.attr("aria-valuenow", complete);
            progressBar.css("width", complete + "%");
        };
        const onComplete = function(bitstreamURI) {
            self.numUploadingFiles--;
            self.numUploadedFiles++;
            if (uploadCompleteCallback) {
                uploadCompleteCallback(file);
            }
            markRowUploadToStagingComplete(fileRow, bitstreamURI);
        };
        const onError = function(message, xhr) {
            self.numUploadingFiles--;
            console.error(xhr);
            if (!message) {
                message = "There was an error uploading the file. " +
                    "If this error persists, please contact us.";
            }
            if (uploadErrorCallback) {
                uploadErrorCallback(file, message);
            } else {
                alert(message);
            }
            fileRow.remove();
        };

        if (uploadInProgressCallback) {
            uploadInProgressCallback();
        }
        new IDEALS.Client().uploadFile(file, itemID,
            onProgressChanged, onComplete, onError);
    };

    filesTable.find("button.remove").on("click", function(e) {
        e.preventDefault();
        onRemoveFileButtonClicked($(this));
    });

    // The file chooser is a file input, hidden via CSS, that is virtually
    // clicked when the drop zone is clicked in order to open a file
    // selection dialog.
    const fileChooser = $(".file-chooser");
    fileChooser.on("change", function() {
        const files = this.files;
        for (let i = 0; i < files.length; i++) {
            addFile(files[i]);
        }
    });

    const dropZone = $(".file-drop-zone");
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
                        console.log(e);
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

};

IDEALS.UIUtils.MetadataEditor = function() {
    $("button.add").on("click", function(e) {
        const last_tr = $(this).parent(".mb-3").find("table.metadata > tbody > tr:last-child");
        const clone = last_tr.clone();
        clone.find("input, textarea").val("");
        clone.find("select:first > option:first").prop("selected", true);
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
};

/**
 * Supports "multi-element lists" (for want of a better term) in forms.
 * These are lists that support a model's one-to-many property where there
 * is one element per property, a remove button next to each element, and
 * an add button after the last element.
 *
 * @constructor
 */
IDEALS.UIUtils.MultiElementList = function(minElements = 1) {
    $("button.add").on("click", function(e) {
        const clone = $(this).prev().clone();
        clone.find("input").val("");
        clone.find("select").attr("disabled", false);
        clone.removeClass("d-none");
        $(this).before(clone);
        updateEventListeners();
        if (clone.hasClass("user")) {
            new IDEALS.UIUtils.UserAutocompleter(clone.find("input"), true);
        }
        e.preventDefault();
    });
    updateEventListeners();

    function updateEventListeners() {
        $("button.remove").off("click").on("click", function () {
            const numIGs   = $(this).parents(".mb-3").find(".input-group").length;
            const parentIG = $(this).parents(".input-group");
            if (numIGs > minElements) {
                // Don't remove the last one, as the add button needs to
                // clone it.
                if (numIGs > 1) {
                    parentIG.remove();
                } else {
                    parentIG.addClass("d-none");
                    parentIG.find("select").attr("disabled", true);
                }
            } else {
                parentIG.find("input").val("");
            }
        });
    }
};

IDEALS.UIUtils.NonNetIDLoginForm = function() {
    const ROOT_URL = $("input[name=root_url]").val();
    const modal    = $("#login-modal");
    const form     = modal.find(".local-credential");
    const flash    = modal.find(".alert.login-status");
    form.find("input[name=password").on("keyup", function() {
        flash.hide();
    });
    form.find("input[name=auth_key]").on("keyup", function() {
        // Ensure that @illinois.edu emails are not used for local auth at
        // UIUC.
        const institutionKey = $("input[name=institution_key]").val();
        if (institutionKey === "uiuc") {
            const submitButton = form.find("button[type=submit]");
            if ($(this).val().endsWith("@illinois.edu")) {
                flash.removeClass("alert-success")
                    .addClass("alert-danger")
                    .text("This login method will not work with an @illinois.edu " +
                        "email address. Use the \"Log in with Illinois " +
                        "NetID\" button instead.")
                    .show();
                submitButton.prop("disabled", true);
            } else {
                flash.hide();
                submitButton.prop("disabled", false);
            }
        }
    });
    form.find("button[type=submit]").on("click", function(event) {
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
};

/**
 * Used in conjunction with the `credentials/password_requirements` partial to
 * provide feedback as a password is being typed.
 */
IDEALS.UIUtils.PasswordRequirements = function() {
    const container     = $("#password-requirements");
    const passwordInput = $("input[name='credential[password]']");
    passwordInput.on("keyup", function() {
        const inputValue     = $(this).val();
        // Min length
        const minLengthLI    = container.find("#min-length");
        const minLength      = parseInt(minLengthLI.data("value"));
        const minLengthCheck = minLengthLI.find("i");
        if (inputValue.length >= minLength) {
            minLengthLI.css("font-weight", "normal");
            minLengthCheck.css("visibility", "visible");
        } else {
            minLengthLI.css("font-weight", "bold");
            minLengthCheck.css("visibility", "hidden");
        }
        // Min lowercase
        const minLowercaseLI    = container.find("#min-lowercase-letters");
        const minLowercase      = parseInt(minLowercaseLI.data("value"));
        const minLowercaseCheck = minLowercaseLI.find("i");
        let matches             = inputValue.match(/[a-z]/g)
        if (matches && matches.length >= minLowercase) {
            minLowercaseLI.css("font-weight", "normal");
            minLowercaseCheck.css("visibility", "visible");
        } else {
            minLowercaseLI.css("font-weight", "bold");
            minLowercaseCheck.css("visibility", "hidden");
        }
        // Min uppercase
        const minUppercaseLI    = container.find("#min-uppercase-letters");
        const minUppercase      = parseInt(minUppercaseLI.data("value"));
        const minUppercaseCheck = minUppercaseLI.find("i");
        matches                 = inputValue.match(/[A-Z]/g)
        if (matches && matches.length >= minUppercase) {
            minUppercaseLI.css("font-weight", "normal");
            minUppercaseCheck.css("visibility", "visible");
        } else {
            minUppercaseLI.css("font-weight", "bold");
            minUppercaseCheck.css("visibility", "hidden");
        }
        // Min numbers
        const minNumbersLI    = container.find("#min-numbers");
        const minNumbers      = parseInt(minNumbersLI.data("value"));
        const minNumbersCheck = minNumbersLI.find("i");
        matches               = inputValue.match(/[0-9]/g);
        if (matches && matches.length >= minNumbers) {
            minNumbersLI.css("font-weight", "normal");
            minNumbersCheck.css("visibility", "visible");
        } else {
            minNumbersLI.css("font-weight", "bold");
            minNumbersCheck.css("visibility", "hidden");
        }
        // Min special chars
        const minSpecialLI    = container.find("#min-special-characters");
        const minSpecial      = parseInt(minSpecialLI.data("value"));
        const characters      = minSpecialLI.data("characters");
        const minSpecialCheck = minSpecialLI.find("i");
        const regex           = new RegExp("[" + characters + "]", "g");
        matches               = inputValue.match(regex);
        if (matches && matches.length >= minSpecial) {
            minSpecialLI.css("font-weight", "normal");
            minSpecialCheck.css("visibility", "visible");
        } else {
            minSpecialLI.css("font-weight", "bold");
            minSpecialCheck.css("visibility", "hidden");
        }
    });
};

/**
 * @return Bootstrap spinner with markup matching that of
 *         ApplicationHelper.spinner().
 */
IDEALS.UIUtils.Spinner = function() {
    return '<div class="d-flex justify-content-center align-items-center" style="height: 100%">' +
        '<div class="spinner-border text-secondary" role="status">' +
        '<span class="sr-only">Loading&hellip;</span>' +
        '</div>' +
        '</div>';
};

/**
 * @param textField {jQuery} Text field element.
 * @param scoped {Boolean} Whether to scope the results to the current
 *                         institution.
 * @constructor
 */
IDEALS.UIUtils.UserAutocompleter = function(textField, scoped) {
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

        new IDEALS.Client().fetchUsers(query, scoped, function(data) {
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
};
