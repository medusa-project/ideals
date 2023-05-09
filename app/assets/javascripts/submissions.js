/**
 * Handles the deposit agreement view.
 *
 * @constructor
 */
const AgreementView = function() {
    // Switch the plus icon in the expand-deposit-agreement section to a minus
    // icon upon click, and vice versa.
    const depositAgreementSection = $('#deposit-agreement');
    depositAgreementSection.on('show.bs.collapse', function () {
        $(this).find("span.text-info").hide();
    });
    depositAgreementSection.on('hide.bs.collapse', function () {
        $(this).find("span.text-info").show();
    });

    // Show the deposit agreement when the begin-submission button is clicked.
    $("button.begin-submission").on("click", function() {
        $(this).fadeOut(IDEALS.FADE_TIME);
        $("#submissions-in-progress").fadeOut(IDEALS.FADE_TIME, function() {
            $("#deposit-agreement").fadeIn(IDEALS.FADE_TIME);
            $("#questions").fadeIn(IDEALS.FADE_TIME);
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
        const result       = validateResponses();
        const submitButton = $("input[type=submit]");
        submitButton.prop("disabled", !result);
        if (result) {
            submitButton.removeClass("btn-secondary");
            submitButton.addClass("btn-success");
        } else {
            submitButton.removeClass("btn-success");
            submitButton.addClass("btn-secondary");
        }
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
    const self = this;
    const form = $("form#properties-form, form#access-form, " +
                   "form#metadata-form, form#files-form");

    var lastEditedInput;

    $("button.step-1-to-2").on("click", function() {
        $("#access-tab").tab("show");
    });
    $("button.step-2-to-3").on("click", function() {
        $("#metadata-tab").tab("show");
    });
    $("button.step-3-to-4").on("click", function() {
        $("#files-tab").tab("show");
    });
    $("button.step-4-to-3").on("click", function() {
        $("#metadata-tab").tab("show");
    });
    $("button.step-3-to-2").on("click", function() {
        $("#access-tab").tab("show");
    });
    $("button.step-2-to-1").on("click", function() {
        $("#properties-tab").tab("show");
    });

    form.on("submit", function(e) {
        e.preventDefault();
        if (lastEditedInput) {
            const row            = lastEditedInput.parents(".row");
            const successMessage = row.find(".message > div.text-success");
            const errorMessage   = row.find(".message > div.text-danger");
            if (lastEditedInput.is(":valid")) {
                $.ajax({
                    type: form.attr("method"),
                    url:  form.attr("action"),
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
     * @param onError {Function} Optional.
     */
    this.save = function(lastEditedInput, onError) {
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
            },
            error: onError
        });
    };

    const setErrorAlert = function(container, message) {
        container.empty();
        if (message != null) {
            container.html("<div class='alert alert-danger'>" + message + "</div>");
            container.show();
        }
    };

    const setInfoAlert = function(container, message) {
        container.empty();
        if (message != null) {
            container.html("<div class='alert alert-info'>" + message + "</div>");
            container.show();
        }
    };

    const clearAlert = function(container) {
        container.empty();
    };

    /****************** Properties/Collections section *********************/

    const propertiesForm    = form.filter("#properties-form");
    const unitsMenu         = $("[name=unit_id]");
    const collectionSection = $("#collection-section");
    const collectionsMenu   = $("[name='item[primary_collection_id]']");

    const setPropertiesError = function(message) {
        setErrorAlert(propertiesForm.find("#properties-messages"), message);
    };

    this.validatePropertiesSection = function() {
        // Check that a collection has been selected.
        if (collectionsMenu.val() > 0) {
            setPropertiesError(null);
        } else {
            setPropertiesError("Please select a unit and collection.");
            return false;
        }
        return true;
    };

    const fetchCollectionsForUnit = function(unitID, onComplete) {
        collectionSection.hide();
        new IDEALS.Client().fetchUnitCollections(unitID, function(data) {
            collectionsMenu.children().remove();
            if (data.length > 0) {
                $.each(data, function (index, value) {
                    collectionsMenu.append(
                        "<option value='" + value[1] + "'>" + value[0] + "</option>");
                });
                collectionSection.show();
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

    /************************** Access section *****************************/

    const accessForm = form.filter("#access-form");

    const setAccessError = function(message) {
        setErrorAlert(accessForm.find("#access-messages"), message);
    };

    this.validateAccessLiftDate = function() {
        return accessForm.find("input[name='item[temp_embargo_expires_at]']").val()
            .match(/\d{4}-\d{2}-\d{2}/) != null;
    }

    this.validateAccessSection = function() {
        if (accessForm.find("input[name='item[temp_embargo_type]']:checked").val() === "closed") {
            if (!self.validateAccessLiftDate()) {
                setAccessError("Lift date must be in YYYY-MM-DD format.");
                return false;
            } else if (!accessForm.find("input[name='item[temp_embargo_reason]']").val().length < 1) {
                setAccessError("Reason is required.");
                return false;
            }
        }
        setAccessError(null);
        return true;
    };

    const showOrHideEmbargoElements = function() {
        const typeRadios               = accessForm.find("input[name='item[temp_embargo_type]']");
        const expirySection            = $("section#expiry-section");
        const reasonSection            = $("section#reason-section");
        const hideRecordsCheckboxGroup = $("section#type-section #item_temp_embargo_kind").parent();
        if (typeRadios.filter(":checked").val() === "closed") {
            hideRecordsCheckboxGroup.show();
            expirySection.show();
            reasonSection.show();
        } else if (typeRadios.filter(":checked").val() === "uofi") {
            hideRecordsCheckboxGroup.hide();
            expirySection.show();
            reasonSection.show();
        } else { // open
            hideRecordsCheckboxGroup.hide();
            expirySection.hide();
            reasonSection.hide();
        }
    };

    accessForm.find("input[name='item[temp_embargo_type]']").on("change", function() {
        showOrHideEmbargoElements();
    });
    showOrHideEmbargoElements();

    accessForm.find("input, select, textarea").on("change", function() {
        self.save($(this));
    });

    accessForm.find("input[name='item[temp_embargo_expires_at]'").on("change", function() {
        const messageDiv     = $(this).parents(".row").find(".message");
        const successMessage = messageDiv.find(".text-success");
        const errorMessage   = messageDiv.find(".text-danger");
        if (self.validateAccessLiftDate()) {
            errorMessage.hide();
        } else {
            successMessage.hide();
            errorMessage.show();
        }
    });

    /************************* Metadata section ****************************/

    const metadataForm = form.filter("#metadata-form");

    const setMetadataError = function(message) {
        setErrorAlert(metadataForm.find("#metadata-messages"), message);
    };

    this.validateMetadataSection = function(includeRequired) {
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

    /**
     * Reads the family name & given name text fields of person-type submission
     * profile elements, and sets the corresponding hidden input value
     * appropriately (in "Familyname, Givenname" format).
     */
    const wirePersonNameTransformer = function() {
        metadataForm.find("[name=family_name], [name=given_name]").on("change", function () {
            const hiddenInput = $("#" + $(this).data("for"));
            const parent      = hiddenInput.parent();
            const familyName  = parent.find("[name=family_name]").val();
            const givenName   = parent.find("[name=given_name]").val();
            hiddenInput.val(familyName + ", " + givenName);
        });
    }

    /**
     * Ensures that the year field of date-type submission profile elements
     * contains a valid year (i.e. no non-numbers and no leading zeroes).
     */
    const wireYearValidator = function() {
        metadataForm.find("[name=year]").on("input", function () {
            const input = $(this);
            input.val(input.val().replace(/[^\d]/g, "")); // only numbers
            input.val(input.val().replace(/\A0/g, ""));    // years may not start with 0
        });
    }

    /**
     * Reads the month & day select menus and year text field of date-type
     * submission profile elements, and sets the corresponding hidden date
     * input value appropriately (in ISO 8601 format).
     */
    const wireDateTransformer = function() {
        $(".value-inputs").each(function() {
            IDEALS.DatePicker($(this).find("[name=year]"),
                $(this).find("[name=month]"),
                $(this).find("[name=day]"));
        });

        metadataForm.find("[name=month], [name=day], [name=year]").on("change", function() {
            const hiddenInput = $("#" + $(this).data("for"));
            const parent      = hiddenInput.parent();
            const month       = parent.find("[name=month]").val(); // may be empty
            const day         = parent.find("[name=day]").val();   // may be empty
            const year        = parent.find("[name=year]").val();
            let date = year
            if (month) {
                date += "-" + month;
                if (day) {
                    date += "-" + day;
                }
            }
            hiddenInput.val(date);
        });
    }

    // When a dc:type of "Other" is selected, add a text field next to it.
    // This is a hack for one UIUC element only since submission profiles don't
    // support this behavior.
    // TODO: add an input type to support this behavior?
    const wireDependentSelects = function() {
        if ($("[name=institution_key]").val() === "uiuc") {
            metadataForm.find("select").on("change", function () {
                if ($(this).parent().prev().val() === "dc:type") {
                    const textField = $(this).next("input");
                    if ($(this).val() === "other") {
                        $(this).attr("name", "disabled");
                        if (textField.length < 1) {
                            // N.B. this must remain in sync with the same tag in the view
                            const textField = $("<input type='text' name='elements[][string]' class='form-control mt-2' required='required'>");
                            $(this).after(textField);
                            wireElementChangeListener(textField);
                        }
                    } else {
                        $(this).attr("name", "elements[][string]");
                        textField.remove();
                    }
                }
            });
        }
    };

    const onElementChanged = function(element) {
        lastEditedInput = element;
        self.validateMetadataSection(false);
        self.save(lastEditedInput);
    };

    /**
     * Shows all adjacent input groups' "remove" buttons if there are two or
     * more of them, and hides them (it) if not.
     */
    const showOrHideRemoveButtons = function() {
        metadataForm.find(".col.remove").each(function() {
            const buttonColumn = $(this);
            const parentInputGroup = buttonColumn.parents(".value-inputs");
            if (parentInputGroup.siblings(".value-inputs").length > 0) {
                buttonColumn.show();
            } else {
                buttonColumn.hide();
            }
        });
    };

    const wireElementChangeListener = function(element) {
        element.on("change", function () {
            onElementChanged($(this));
        });
    }

    const wireElementChangeListeners = function() {
        wireElementChangeListener(metadataForm.find("input[type=text], select, textarea"));
    };

    const wireRemoveButtons = function() {
        metadataForm.find("button.remove").off("click").on("click", function() {
            const parentInputGroup  = $(this).parents(".value-inputs");
            // Don't remove the input group if it's the last one remaining
            const siblings = parentInputGroup.siblings(".value-inputs");
            if (siblings.length > 0) {
                parentInputGroup.remove();
                onElementChanged(siblings.filter(":first"));
                showOrHideRemoveButtons();
            }
        });
    };

    showOrHideRemoveButtons();
    wireRemoveButtons();
    wireDependentSelects();
    wirePersonNameTransformer();
    wireDateTransformer();
    wireYearValidator();
    wireElementChangeListeners();

    metadataForm.find("button.add").on("click", function(e) {
        // Show the "remove" button of all adjacent input groups
        const inputGroups = $(this).parent().find(".value-inputs");
        inputGroups.find(".remove").show();
        // Clone the last input group
        const prevInputGroup = inputGroups.last();
        const clone = prevInputGroup.clone();
        // Clear out its value
        clone.find("input[type=text], input[data-input-type=person], select, textarea").val("");
        if (clone.find("select").length > 0) {
            //clone.find("select").attr("name", "elements[][string]");
            clone.find("input[type=hidden]").filter(function() {
                return $(this).attr("name") !== "elements[][name]";
            }).val("");
        }
        const hiddenDateOrPerson = clone.find("[data-input-type=date], [data-input-type=person]");
        if (hiddenDateOrPerson) {
            const hiddenID = IDEALS.Util.randomString(16);
            hiddenDateOrPerson.attr("id", hiddenID);
            clone.find("input[type=text], select").each(function(i, input) {
                $(input).attr("data-for", hiddenID);
            });
        }
        // Insert the clone after the last input group
        prevInputGroup.after(clone);
        wireRemoveButtons();
        wireDependentSelects();
        wirePersonNameTransformer();
        wireDateTransformer();
        wireYearValidator();
        wireElementChangeListeners();
    });

    /*************************** Files section *****************************/

    const filesForm            = form.filter("#files-form");
    const uploader             = new IDEALS.ItemFileUploader();
    const completionForm       = $("#completion-form");
    const formSubmitButton     = completionForm.find("input[type=submit]");
    const fileMessageContainer = filesForm.find("#files-messages");

    uploader.onUploadInProgress(function() {
        setInfoAlert(fileMessageContainer, "Uploading is in progress. " +
            "Please wait for this notice to disappear.");
        formSubmitButton.prop("disabled", true);
    });
    uploader.onUploadComplete(function(file) {
        if (uploader.numUploadingFiles < 1) {
            clearAlert(fileMessageContainer);
            formSubmitButton.prop("disabled", false);
        }
    });
    uploader.onUploadError(function(file, message) {
        setErrorAlert(fileMessageContainer, message);
    });
    uploader.onRemoveFileComplete(function() {});
    uploader.onRemoveFileError(function(message) {
        setErrorAlert(fileMessageContainer, message);
    });

    this.validateFilesSection = function() {
        if (uploader.numUploadingFiles > 0) {
            setErrorAlert(fileMessageContainer, "Please wait for file uploads to complete.");
            return false;
        } else if (uploader.numUploadedFiles < 1) {
            setErrorAlert(fileMessageContainer, "You must upload at least one file.");
            return false;
        }
        clearAlert(fileMessageContainer);
        return true;
    };

    // Validate everything before submitting.
    formSubmitButton.on("click", function(e) {
        if (!self.validatePropertiesSection()) {
            $("#properties-tab").click();
            return false;
        }
        if (!self.validateAccessSection()) {
            $("#access-tab").click();
            return false;
        }
        if (!self.validateMetadataSection(true)) {
            $("#metadata-tab").click();
            return false;
        }
        if (!self.validateFilesSection()) {
            return false;
        }
    });
};

/**
 * Handles the submission form.
 *
 * @constructor
 */
const EditSubmissionView = function() {
    new SubmissionForm();
};

$(document).ready(function() {
    if ($("body#deposit-agreement-body").length) {
        new AgreementView();
    } else if ($("body#edit_submission").length) {
        new EditSubmissionView();
    }
});