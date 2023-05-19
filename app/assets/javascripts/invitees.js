/**
 * Handles list-invitees view.
 *
 * @constructor
 */
const InviteesView = function() {
    const ROOT_URL    = $("input[name=root_url]").val();
    const form        = $("#invitees-form");
    const filterField = $("[name=q]");
    const container   = $("#invitees-xhr-content");

    const attachResultsEventListeners = function() {
        $(".page-link").on("click", function(e) {
            e.preventDefault();
            refreshResults($(this).attr("href"));
        });
    };

    const refreshResults = function(url) {
        container.html(IDEALS.UIUtils.Spinner());
        if (!url) {
            url = form.attr("action");
        }
        console.log(url);
        console.log(form.serialize());
        $.ajax({
            method:  "GET",
            url:     url,
            data:    form.serialize(),
            dataType: "script",
            success: function(data) {
                container.html(data);
                attachResultsEventListeners();
            },
            error:   function(data, status, xhr) {
                console.log(data);
                console.log(status);
                console.log(xhr);
            }
        });
    };

    let timeout = null;
    filterField.on("keyup", function() {
        clearTimeout(timeout);
        timeout = setTimeout(refreshResults, IDEALS.UIUtils.KEY_DELAY);
    });
    $("[name=institution_id], [name=approval_state]").on("change", function() {
        refreshResults();
    });
};

$(document).ready(function() {
    if ($("body#list_invitees").length) {
        new InviteesView();
    }
});
