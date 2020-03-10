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
 * Handles the edit-item view used during submission.
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

    $("input, select, textarea").on("change", function() {
        console.log("form changed");
    });
};

$(document).ready(function() {
    if ($("body#agreement").length) {
        new AgreementView();
    } else if ($("body#edit_submission")) {
        new EditView();
    }
});