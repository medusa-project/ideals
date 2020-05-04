/**
 * Handles list-invitees view.
 *
 * @constructor
 */
const InviteesView = function() {
    $("button[type=reset]").on("click", function() {
        const form = $(this).parents("form");
        $("[name=approval_state]").val("");
        form.trigger("reset");
        form.submit();
    });

    $("[name=approval_state]").on("change", function() {
        $(this).parents("form:first").submit();
    });

    // Select the approval state based on the URL query argument, as the
    // browser won't do this automatically.
    const argName   = "approval_state";
    const queryArgs = new URLSearchParams(location.search);
    if (queryArgs.has(argName)) {
        $("select[name=approval_state]").val(queryArgs.get(argName));
    }
};

$(document).ready(function() {
    if ($("body#list_invitees").length) {
        new InviteesView();
    }
});
