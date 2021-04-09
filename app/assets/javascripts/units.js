/**
 * Handles list-units view.
 *
 * @constructor
 */
const UnitsView = function() {
    new IDEALS.ExpandableResourceList();
    new IDEALS.UserAutocompleter(
        $("input[name=primary_administrator], input[name='administering_users[]']"));
    new IDEALS.MultiElementList();
};

/**
 * Handles show-unit view.
 *
 * @constructor
 */
const UnitView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();
    const unitID   = $("[name=unit_id]").val();

    $("#properties-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/units/" + unitID + "/properties";
        $.get(url, function(data) {
            $("#properties-tab-content").html(data);
            $('.edit-unit-properties').on("click", function() {
                const url = ROOT_URL + "/units/" + unitID + "/edit-properties";
                $.get(url, function(data) {
                    $("#edit-unit-properties-modal .modal-body").html(data);
                });
            });
        });
    }).trigger("show.bs.tab");

    $("#units-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/units/" + unitID + "/units";
        $.get(url, function(data) {
            $("#units-tab-content").html(data);
            $('.edit-unit-membership').on("click", function () {
                const url = ROOT_URL + "/units/" + unitID + "/edit-membership";
                $.get(url, function (data) {
                    $("#edit-unit-membership-modal .modal-body").html(data);
                });
            });
        });
    });

    $("#collections-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/units/" + unitID + "/collections";
        $.get(url, function(data) {
            $("#collections-tab-content").html(data);
        });
    });

    $("#items-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/units/" + unitID + "/items";
        $.get(url, function(data) {
            $("#items-tab-content").html(data);
        });
    });

    $("#statistics-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/units/" + unitID + "/statistics";
        $.get(url, function(data) {
            const statsTabContent = $("#statistics-tab-content");
            statsTabContent.html(data);

            const refreshStatisticsByMonth = function() {
                const innerTabContent = $("#statistics-by-month-tab-content");
                innerTabContent.html(IDEALS.Spinner());
                const url = ROOT_URL + "/units/" + unitID + "/statistics-by-range?" +
                    statsTabContent.find("form").serialize();
                $.get(url, function (data) {
                    innerTabContent.html(data);
                });
            };
            const refreshDownloadsByItem = function() {
                const innerTabContent = $("#downloads-by-item-tab-content");
                innerTabContent.html(IDEALS.Spinner());
                const url = ROOT_URL + "/units/" + unitID + "/item-download-counts?" +
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

    $("#access-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/units/" + unitID + "/access";
        $.get(url, function(data) {
            $("#access-tab-content").html(data);
            $('.edit-unit-access').on("click", function () {
                const id = $(this).data("unit-id");
                const url = ROOT_URL + "/units/" + unitID + "/edit-access";
                $.get(url, function (data) {
                    $("#edit-unit-access-modal .modal-body").html(data);
                    new IDEALS.UserAutocompleter(
                        $("input[name=primary_administrator], input[name='administering_users[]']"));
                    new IDEALS.MultiElementList();
                });
            });
        });
    });
};

$(document).ready(function() {
    if ($("body#list_units").length) {
        new UnitsView();
    } else if ($("body#show_unit").length) {
        new UnitView();
    }
});
