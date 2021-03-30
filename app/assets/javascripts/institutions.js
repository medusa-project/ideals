/**
 * Handles show-institution view (/institutions/:key).
 *
 * @constructor
 */
const InstitutionView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    $('button.edit-institution').on("click", function() {
        const key = $(this).data("institution-key");
        const url = ROOT_URL + "/institutions/" + key + "/edit";
        $.get(url, function(data) {
            $("#edit-institution-modal .modal-body").html(data);
        });
    });

    // Statistics tab
    const statistics_content = $("#statistics-xhr-content");
    const refreshStatistics = function(key) {
        const url = ROOT_URL + "/institutions/" + key + "/statistics?" +
            $("#statistics-tab-content form").serialize();
        $.get(url, function(data) {
            statistics_content.prev().hide(); // hide the spinner
            statistics_content.html(data);
        });
    };

    const statistics_tab = $('#statistics-tab');
    statistics_tab.on('show.bs.tab', function() {
        const key = $(this).data("institution-key");
        refreshStatistics(key);
    });
    $("#statistics-tab-content input[type=submit]").on("click", function() {
        // Remove existing content and show the spinner
        statistics_content.empty();
        statistics_content.prev().show(); // show the spinner

        const key = statistics_tab.data("institution-key");
        refreshStatistics(key);
        return false;
    });
};

$(document).ready(function() {
    if ($('body#show_institution').length) {
        new InstitutionView();
    }
});
