/**
 * Handles global statistics view (/statistics).
 *
 * @constructor
 */
const StatisticsView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    $("#items-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/statistics/items";
        $.get(url, function (data) {
            $("#items-tab-content").html(data);
        });
    }).trigger("show.bs.tab");

    $("#files-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/statistics/files";
        $.get(url, function (data) {
            $("#files-tab-content").html(data);
        });
    });
};


$(document).ready(function() {
    if ($('body#statistics').length) {
        new StatisticsView();
    }
});
