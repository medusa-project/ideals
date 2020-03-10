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
    new IDEALS.DepositMetadataEditor();

    var lastEditedInput;
    $("input, select, textarea").on("change", function() {
        lastEditedInput = $(this);
        $(this).parents("form").submit();
    });

    $("form#deposit-metadata-form").on("submit", function(e) {
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

    $("#deposit-files-form input[type=submit]").on("click", function() {
        $(this).parent().append("<input type=\"hidden\" name=\"submitting\" value=\"false\">");
    });

    $("#deposit-files-form").on("submit", function(e) {
        $("#complete-modal").modal("show");
    });
};

$(document).ready(function() {
    if ($("body#agreement").length) {
        new AgreementView();
    } else if ($("body#edit_submission").length) {
        new EditView();
    }
});