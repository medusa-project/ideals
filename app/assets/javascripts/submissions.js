/**
 * Handles the deposit agreement view.
 *
 * @constructor
 */
const AgreementView = function() {
    // Show the deposit agreement when the begin-submission button is clicked.
    $("button.begin-submission").on("click", function() {
        $(this).parents(".card").fadeOut(IDEALS.FADE_TIME, function() {
            $("#deposit-agreement").fadeIn(IDEALS.FADE_TIME);
        });
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

    var lastEditedInput;
    $("input, select, textarea").on("change", function() {
        lastEditedInput = $(this);
        validate(false);
        $(this).parents("form").submit();
        const successMessage = $(this).parents(".row").find(".message > div.text-success");
        successMessage.show();
        setTimeout(function () {
            successMessage.fadeOut();
        }, 4000);
    });

    const metadataForm = $("form#deposit-metadata-form");
    metadataForm.on("submit", function(e) {
        e.preventDefault();
        const tr             = lastEditedInput.parents("tr");
        const successMessage = tr.find("td.message > div.text-success");
        const errorMessage   = tr.find("td.message > div.text-danger");
        if (lastEditedInput && lastEditedInput.is(":valid")) {
            const form = $(this);
            $.ajax({
                type: form.attr("method"),
                url: form.attr("action"),
                data: form.serialize(),
                complete: function (request) {
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

    $("form#complete-form input[type=submit]").on("click", function(e) {
        if (!validate(true)) {
            $("#metadata-tab").click();
            e.preventDefault();
            return false;
        }
    });

    $("#complete-form").on("submit", function() {
        $("#complete-modal").modal("show");
    });

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

    function validate(includeRequired) {
        let isValid = true;
        metadataForm.find("input[required], textarea[required]").each(function() {
            if ($(this).val().length < 1) {
                isValid = false;
            }
        });
        const messages = metadataForm.find(".error-messages");
        if (isValid) {
            messages.empty();
            return true;
        } else if (includeRequired) {
            messages.html("<div class=\"alert alert-danger\">" +
                "Please ensure that all required elements are filled in.</div>");
            return false;
        }
    };

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
    new DepositMetadataEditor();
};

$(document).ready(function() {
    if ($("body#agreement").length) {
        new AgreementView();
    } else if ($("body#edit_submission").length) {
        new EditView();
    }
});