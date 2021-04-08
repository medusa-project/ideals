/**
 * Handles show-institution view (/institutions/:key).
 *
 * @constructor
 */
const InstitutionView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();
    const institutionKey = $("[name=institution_key]").val();

    $("#properties-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/institutions/" + institutionKey + "/properties";
        $.get(url, function (data) {
            $("#properties-tab-content").html(data);
            $('button.edit-institution').on("click", function() {
                const url = ROOT_URL + "/institutions/" + institutionKey + "/edit";
                $.get(url, function(data) {
                    $("#edit-institution-modal .modal-body").html(data);
                });
            });
        });
    }).trigger("show.bs.tab");

    $("#users-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/institutions/" + institutionKey + "/users";
        $.get(url, function (data) {
            $("#users-tab-content").html(data);
        });
    }).trigger("show.bs.tab");

    $("#statistics-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/institutions/" + institutionKey + "/statistics";
        $.get(url, function(data) {
            const statsTabContent = $("#statistics-tab-content");
            statsTabContent.html(data);

            const refreshStatisticsByMonth = function() {
                const innerTabContent = $("#statistics-by-month-tab-content");
                innerTabContent.html(IDEALS.Spinner());
                const url = ROOT_URL + "/institutions/" + institutionKey + "/statistics-by-range?" +
                    statsTabContent.find("form").serialize();
                $.get(url, function (data) {
                    innerTabContent.html(data);
                });
            };
            const refreshDownloadsByItem = function() {
                const innerTabContent = $("#downloads-by-item-tab-content");
                innerTabContent.html(IDEALS.Spinner());
                const url = ROOT_URL + "/institutions/" + institutionKey + "/item-download-counts?" +
                    statsTabContent.find("form").serialize();
                $.get(url, function (data) {
                    innerTabContent.html(data);
                });
            };

            $("#statistics-by-month-tab").on("show.bs.tab", function() {
                refreshStatisticsByMonth()
            }).trigger("show.bs.tab");
            $("#downloads-by-item-tab").on("show.bs.tab", function() {
                refreshDownloadsByItem();
            });

            statsTabContent.find("input[type=submit]").on("click", function () {
                const activeSubTabContent = statsTabContent.find(".tab-content .active");
                switch (activeSubTabContent.prop("id")) {
                    case "statistics-by-month-tab-content":
                        refreshStatisticsByMonth();
                        break;
                    case "downloads-by-item-tab-content":
                        refreshDownloadsByItem();
                        break;
                }
                return false;
            });
        });
    });
};

$(document).ready(function() {
    if ($('body#show_institution').length) {
        new InstitutionView();
    }
});
