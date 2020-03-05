/**
 * @constructor
 */
const DepositView = function() {
    const FADE_TIME = 200;
    // Show the deposit agreement when the begin-submission button is clicked.
    $("button.begin-submission").on("click", function() {
        $(this).parents(".card").fadeOut(FADE_TIME, function() {
            $("#deposit-agreement").fadeIn(FADE_TIME);
        });
    });
};

$(document).ready(function() {
    if ($("body#deposit").length) {
        new DepositView();
    }
});
