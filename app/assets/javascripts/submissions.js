/**
 * Handles the deposit agreement view.
 *
 * @constructor
 */
const AgreementView = function() {
    // Show the deposit agreement when the begin-submission button is clicked.
    $("button.begin-submission").on("click", function() {
        $(this).fadeOut(IDEALS.FADE_TIME);
        $(".submissions-in-progress").fadeOut(IDEALS.FADE_TIME, function() {
            $("#deposit-agreement").fadeIn(IDEALS.FADE_TIME);
        });
    });

    const allQuestionsAnswered = function() {
        return $("input.response:checked").length >= $(".question").length;
    };

    const validateResponses = function() {
        if (!allQuestionsAnswered()) {
            return false;
        }
        // Check that all answers are acceptable.
        const a1 = $("input[name=q1]:checked").val().toLowerCase();
        const a2 = $("input[name=q2]:checked").val().toLowerCase();
        const a3 = $("input[name=q3]:checked").val().toLowerCase();
        return (a1 === "yes" &&
            (a2 === "yes" || a2 === "not applicable") &&
            a3 === "yes");
    };

    const conditionallyShowFeedback = function() {
        const feedbackAlert = $("#feedback");
        if (allQuestionsAnswered()) {
            if (validateResponses()) {
                feedbackAlert.hide();
            } else {
                feedbackAlert.show();
            }
        } else {
            feedbackAlert.hide();
        }
    };

    const conditionallyEnableSubmitButton = function() {
        $("input[type=submit]").prop("disabled", !validateResponses());
    };

    $("input.response").on("click", function() {
        conditionallyShowFeedback();
        conditionallyEnableSubmitButton();
    });

    conditionallyEnableSubmitButton();
};

/**
 * Manages the deposit form.
 *
 * @constructor
 */
const SubmissionForm = function() {
    const ROOT_URL   = $("input[name=root_url]").val();
    const CSRF_TOKEN = $("input[name=authenticity_token]").val();

    const self            = this;
    const form            = $("form.edit_item");
    // Properties section
    const propertiesForm  = form.filter("#properties-form");
    const unitsMenu       = $("[name=unit_id]");
    const collectionsMenu = $("[name='item[primary_collection_id]']");
    // Metadata section
    const metadataForm    = form.filter("#metadata-form");
    // Files section
    const filesForm       = form.filter("#files-form");
    const uploader        = new IDEALS.ItemFileUploader();
    // Files section
    const completionForm  = form.filter("#completion-form");

    var lastEditedInput;

    $("button.step-1-to-2").on("click", function() {
        $("#metadata-tab").tab("show");
    });
    $("button.step-2-to-3").on("click", function() {
        $("#files-tab").tab("show");
    });
    $("button.step-3-to-2").on("click", function() {
        $("#metadata-tab").tab("show");
    });
    $("button.step-2-to-1").on("click", function() {
        $("#properties-tab").tab("show");
    });

    form.on("submit", function(e) {
        e.preventDefault();
        if (lastEditedInput) {
            const tr             = lastEditedInput.parents("tr");
            const successMessage = tr.find("td.message > div.text-success");
            const errorMessage   = tr.find("td.message > div.text-danger");
            if (lastEditedInput.is(":valid")) {
                $.ajax({
                    type: form.attr("method"),
                    url: form.attr("action"),
                    data: form.serialize(),
                    success: function () {
                        successMessage.show();
                        errorMessage.hide();
                        setTimeout(function () {
                            successMessage.fadeOut();
                        }, 4000);
                    }
                });
            } else {
                successMessage.hide();
                errorMessage.show();
            }
        }
    });

    /**
     * Should be called after every valid edit (except file uploads).
     *
     * @param lastEditedInput {jQuery}
     */
    this.save = function(lastEditedInput) {
        const localForm = lastEditedInput.parents("form");
        $.ajax({
            type: localForm.attr("method"),
            url:  localForm.attr("action"),
            data: localForm.serialize(),
            success: function() {
                const successMessage = lastEditedInput.parents("tr, .row").find(".message > .text-success");
                successMessage.show();
                setTimeout(function () {
                    successMessage.fadeOut();
                }, 4000);
            }
        });
    };

    const setPropertiesError = function(message) {
        const messages = propertiesForm.find("#properties-messages");
        messages.empty();
        if (message != null) {
            messages.html("<div class='alert alert-danger'>" + message + "</div>");
        }
    };

    const setMetadataError = function(message) {
        const messages = metadataForm.find("#metadata-messages");
        messages.empty();
        if (message != null) {
            messages.html("<div class='alert alert-danger'>" + message + "</div>");
        }
    };

    const setFilesError = function(message) {
        const messages = filesForm.find("#files-messages");
        messages.empty();
        if (message != null) {
            messages.html("<div class='alert alert-danger'>" + message + "</div>");
        }
    };

    this.validateProperties = function() {
        // Check that a collection has been selected.
        if (collectionsMenu.val() > 0) {
            setPropertiesError(null);
        } else {
            setPropertiesError("Please ensure that a collection has been selected.");
            return false;
        }
        return true;
    };

    this.validateMetadata = function(includeRequired) {
        // Check that all required elements are filled in.
        let isValid = true;
        metadataForm.find("input[required], textarea[required]").each(function() {
            if ($(this).val().length < 1) {
                isValid = false;
            }
        });
        if (isValid) {
            setMetadataError(null);
        } else if (includeRequired) {
            setMetadataError("Please ensure that all required elements are filled in.");
            return false;
        }
        return true;
    };

    this.validateFiles = function() {
        setFilesError(null);
        // Check that at least one file has been uploaded.
        if (uploader.numUploadedFiles() < 1) {
            setFilesError("You must upload at least one file.");
            return false;
        }
        // Check that there are no uploads in progress.
        if (uploader.numUploadingFiles() > 0) {
            setFilesError("Wait for file uploads to complete.");
            return false;
        }
        return true;
    };

    /****************** Properties/Collections section *********************/

    const fetchCollectionsForUnit = function(unitID, onComplete) {
        collectionsMenu.attr("disabled", true);
        new IDEALS.Client().fetchUnitCollections(unitID, function(data) {
            collectionsMenu.children().remove();
            if (data.length > 0) {
                $.each(data, function (index, value) {
                    collectionsMenu.append(
                        "<option value='" + value[1] + "'>" + value[0] + "</option>");
                });
                collectionsMenu.attr("disabled", false);
            }
            if (onComplete) {
                onComplete();
            }
        });
    };

    unitsMenu.on("change", function() {
        fetchCollectionsForUnit($(this).val(), function() {
            // (No need to validate as this menu is always valid)
            self.save(collectionsMenu);
        });
    });

    collectionsMenu.on("change", function() {
        // (No need to validate as this menu is always valid)
        self.save(collectionsMenu);
    });

    // Restore initial unit & collection selection values. If there is nothing
    // to restore, select the blank item in the unit menu, and hide the
    // collection menu.
    let unitID = $("[name='item[initial_primary_collection_unit_id]']").val();
    if (unitID > 0) {
        fetchCollectionsForUnit(unitID, function () {
            unitsMenu.val(unitID);
            const collectionID = $("[name='item[initial_primary_collection_id]']").val();
            if (collectionID > 0) {
                collectionsMenu.val(collectionID);
            }
            self.save(collectionsMenu);
        });
    }

    /************************* Metadata section ****************************/

    /**
     * Reads the month, day, and year select menus of date-type submission
     * profile elements, and sets the corresponding hidden date input value
     * appropriately (in "Month DD, YYYY" format).
     */
    metadataForm.find("[name=month], [name=day], [name=year]").on("change", function() {
        const hiddenInput = $("#" + $(this).data("for"));
        const parent      = hiddenInput.parent();
        const month       = parent.find("[name=month]").val();
        const day         = parent.find("[name=day]").val();
        const year        = parent.find("[name=year]").val();
        hiddenInput.val(month + " " + day + ", " + year);
    });

    metadataForm.find("input, select, textarea").on("change", function() {
        lastEditedInput = $(this);
        self.validateMetadata(false);
        self.save(lastEditedInput);
    });

    /**
     * Shows all adjacent input groups' "remove" buttons if there are two or
     * more of them, and hides them (it) if not.
     */
    const refreshRemoveButtons = function() {
        metadataForm.find("button.remove").each(function() {
            const button = $(this);
            const parentInputGroup = button.parents(".input-group");
            if (parentInputGroup.siblings(".input-group").length > 0) {
                button.parent().show();
            } else {
                button.parent().hide();
            }
        });
    };

    const wireRemoveButtons = function() {
        metadataForm.find("button.remove").off("click").on("click", function(e) {
            const parentInputGroup = $(this).parents(".input-group");
            if (parentInputGroup.siblings(".input-group").length > 0) {
                parentInputGroup.remove();
            }
            refreshRemoveButtons();
            e.preventDefault();
        });
    };

    refreshRemoveButtons();
    wireRemoveButtons();

    metadataForm.find("button.add").on("click", function(e) {
        // Show the "remove" button of all adjacent input groups
        const inputGroups = $(this).parent().find(".input-group");
        inputGroups.find(".input-group-append").show();
        // Clone the last input group
        const prevInputGroup = inputGroups.last();
        const clone = prevInputGroup.clone();
        clone.find("input[type=text], textarea").val("");
        // Insert the clone after the last input group
        prevInputGroup.after(clone);
        wireRemoveButtons();
        e.preventDefault();
    });

    /*************************** Files section *****************************/

    // Rather than submitting the form, this button validates everything, sends
    // a POST request to the submission-complete route, and finally opens the
    // "submission complete" modal. (Everything in the form has been submitted
    // via XHR already.)
    completionForm.find("input[type=submit]").on("click", function(e) {
        e.preventDefault();
        if (!self.validateProperties()) {
            $("#properties-tab").click();
            return false;
        }
        if (!self.validateMetadata(true)) {
            $("#metadata-tab").click();
            return false;
        }
        if (!self.validateFiles()) {
            return false;
        }
        $.ajax({
            type:    "POST",
            url:     ROOT_URL + $('[name=complete_submission_path]').val(),
            headers: { "X-CSRF-Token": CSRF_TOKEN },
            success: function() {
                $("#complete-modal").modal("show");
            },
            error:   function(xhr, status, request) {
                console.log(xhr);
                console.log(status);
                console.log(request);
                setFilesError("The submission failed to complete. This may be a bug.");
            }
        });
        return false;
    });
};

/**
 * Handles the submission form.
 *
 * @constructor
 */
const EditView = function() {
    new SubmissionForm();
};

$(document).ready(function() {
    if ($("body#agreement").length) {
        new AgreementView();
    } else if ($("body#edit_submission").length) {
        new EditView();
    }
});