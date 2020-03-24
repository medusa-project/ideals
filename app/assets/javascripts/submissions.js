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
};

/**
 * Manages the deposit form.
 *
 * @constructor
 */
const DepositForm = function() {

    const self = this;
    const form = $("form.edit_item");

    var lastEditedInput;
    form.find("input, select, textarea").on("change", function() {
        lastEditedInput = $(this);
        self.validate(false);
        self.save(lastEditedInput);
    });

    form.on("submit", function(e) {
        e.preventDefault();
        const tr             = lastEditedInput.parents("tr");
        const successMessage = tr.find("td.message > div.text-success");
        const errorMessage   = tr.find("td.message > div.text-danger");
        if (lastEditedInput && lastEditedInput.is(":valid")) {
            $.ajax({
                type: form.attr("method"),
                url:  form.attr("action"),
                data: form.serialize(),
                success: function() {
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
    });

    this.save = function(lastEditedInput) {
        const localForm = lastEditedInput.parents("form");
        $.ajax({
            type: localForm.attr("method"),
            url:  localForm.attr("action"),
            data: localForm.serialize(),
            success: function() {
                const successMessage = lastEditedInput.parents(".row").find(".message > .text-success");
                successMessage.show();
                setTimeout(function () {
                    successMessage.fadeOut();
                }, 4000);
            }
        });
    };

    this.validate = function(includeRequired) {
        let isValid = true;
        form.find("input[required], textarea[required]").each(function() {
            if ($(this).val().length < 1) {
                isValid = false;
            }
        });
        const messages = form.find(".error-messages");
        if (isValid) {
            messages.empty();
            return true;
        } else if (includeRequired) {
            messages.html("<div class=\"alert alert-danger\">" +
                "Please ensure that all required elements are filled in.</div>");
            return false;
        }
    };

    const fetchCollectionsForUnit = function(unitID, onComplete) {
        collectionsMenu.attr("disabled", true);
        const ROOT_URL = $("input[name=root_url]").val();
        $.ajax({
            method: "GET",
            url: ROOT_URL + "/units/" + unitID + "/collections",
            success: function (data) {
                collectionsMenu.children().remove();
                if (data.length > 0) {
                    $.each(data, function (index, value) {
                        collectionsMenu.append(
                            "<option value=\"" + value[1] + "\">" + value[0] + "</option>");
                    });
                    collectionsMenu.attr("disabled", false);
                }
                if (onComplete) {
                    onComplete();
                }
            }
        });
    };

    const selectUnit = function(unitID) {
        unitsMenu.val(unitID);
    };

    const selectCollection = function(collectionID) {
        collectionsMenu.val(collectionID);
    };

    const unitsMenu       = $("[name=unit_id]");
    const collectionsMenu = $("[name='item[primary_collection_id]']");

    unitsMenu.on("change", function(e) {
        fetchCollectionsForUnit($(this).val(), function() {
            self.save(collectionsMenu);
        });
    });

    // Restore initial unit & collection selection values.
    const unitID = $("[name='item[initial_primary_collection_unit_id]']").val();
    if (unitID > 0) {
        fetchCollectionsForUnit(unitID, function() {
            selectUnit(unitID);
            const collectionID = $("[name='item[initial_primary_collection_id]']").val();
            if (collectionID > 0) {
                selectCollection(collectionID);
            }
        });
    }

    const completeForm = $("form#complete-form");
    completeForm.find("input[type=submit]").on("click", function(e) {
        if (!self.validate(true)) {
            $("#metadata-tab").click();
            e.preventDefault();
            return false;
        }
    });

    completeForm.on("submit", function() {
        $("#complete-modal").modal("show");
    });
};

/**
 * Manages the deposit metadata form.
 *
 * @constructor
 */
const DepositMetadataEditor = function() {

    refreshRemoveButtons();
    wireRemoveButtons();

    $("button.add").on("click", function(e) {
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

    /**
     * Shows all adjacent input groups' "remove" buttons if there are two
     * or more of them, and hides them (it) if not.
     */
    function refreshRemoveButtons() {
        $("button.remove").each(function() {
            const button = $(this);
            const parentInputGroup = button.parents(".input-group");
            if (parentInputGroup.siblings(".input-group").length > 0) {
                button.parent().show();
            } else {
                button.parent().hide();
            }
        });
    }

    function wireRemoveButtons() {
        $("button.remove").off("click").on("click", function(e) {
            const parentInputGroup = $(this).parents(".input-group");
            if (parentInputGroup.siblings(".input-group").length > 0) {
                parentInputGroup.remove();
            }
            refreshRemoveButtons();
            e.preventDefault();
        });
    }
};

/**
 * Handles the submission form.
 *
 * @constructor
 */
const EditView = function() {
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
    new DepositForm();
    new DepositMetadataEditor();
};

$(document).ready(function() {
    if ($("body#agreement").length) {
        new AgreementView();
    } else if ($("body#edit_submission").length) {
        new EditView();
    }
});