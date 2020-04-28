/**
 * Handles list-invitees view.
 *
 * @constructor
 */
const InviteesView = function() {
    $("button[type=reset]").on("click", function() {
        const form = $(this).parents("form");
        form.trigger("reset");
        form.submit();
    });
};

$(document).ready(function() {
    if ($("body#list_invitees").length) {
        new InviteesView();
    }
});
