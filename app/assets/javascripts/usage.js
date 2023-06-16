/**
 * Handles global usage view (/usage).
 *
 * @constructor
 */
const UsageView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    $("#items-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/usage/items";
        $.get(url, function (data) {
            $("#items-tab-content").html(data);
        });
    }).trigger("show.bs.tab");

    $("#files-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/usage/files";
        $.get(url, function (data) {
            $("#files-tab-content").html(data);
        });
    });
};


$(document).ready(function() {
    if ($("body#usage").length) {
        new UsageView();
    }
});
