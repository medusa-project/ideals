/**
 * Handles list-units view.
 *
 * @constructor
 */
const UnitsView = function() {
    new IDEALS.ExpandableResourceList();
    new IDEALS.LocalUserAutocompleter(
        $("input[name=primary_administrator], input[name='administering_users[]']"));
    new IDEALS.MultiElementList();

    $(".add-unit").on("click", function() {
        const url = "/units/new";
        $.get(url, function(data) {
            $("#add-unit-modal .modal-body").html(data);
        });
    });
};

/**
 * Handles show-unit view.
 *
 * @constructor
 */
const UnitView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();
    const unitID   = $("[name=unit_id]").val();

    $("#about-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/units/" + unitID + "/about";
        $.get(url, function(data) {
            $("#about-tab-content").html(data);
            $('.edit-unit-about').on("click", function() {
                const url = ROOT_URL + "/units/" + unitID + "/edit-about";
                $.get(url, function(data) {
                    $("#edit-unit-about-modal .modal-body").html(data);
                });
            });
            $('.edit-unit-membership').on("click", function () {
                const url = ROOT_URL + "/units/" + unitID + "/edit-membership";
                $.get(url, function (data) {
                    $("#edit-unit-membership-modal .modal-body").html(data);
                });
            });
        });
    });

    $("#items-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/units/" + unitID + "/items";
        $.get(url, function(data) {
            const tabContent = $("#items-tab-content");
            tabContent.html(data);

            const searchForm      = tabContent.find("form");
            const searchFields    = searchForm.find("input[type=text], input[type=search], textarea");
            const searchControls  = searchForm.find("input[type=radio], input[type=checkbox], select");
            const sortMenu        = tabContent.find("select[name=sort]");
            const directionRadios = tabContent.find("input[name=direction]");

            const attachResultsEventListeners = function() {
                $(".page-link").on("click", function(e) {
                    e.preventDefault();
                    refreshResults($(this).attr("href"));
                });
            };

            const refreshResults = function(url) {
                const container = $("#items-xhr-content");
                container.html(IDEALS.Spinner());
                if (!url) {
                    url = ROOT_URL + "/units/" + unitID + "/item-results";
                }
                $.ajax({
                    method:  "GET",
                    url:     url,
                    data:    searchForm.serialize(),
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
            searchFields.on("keyup", function() {
                clearTimeout(timeout);
                timeout = setTimeout(function() {
                    refreshResults();
                }, IDEALS.KEY_DELAY);
            });
            searchControls.on("change", function() {
                refreshResults();
            });
            // When the search-type tab is changed, clear the input from all
            // other tabs.
            tabContent.find('a[data-toggle="pill"]').on('hidden.bs.tab', function(e) {
                const hiddenPane = $($(e.target).attr("href"));
                hiddenPane.find("input[type=text], input[type=search], textarea").val("");
                searchControls.trigger("change");
            });

            const showOrHideDirectionRadios = function() {
                const directionButtonGroup = directionRadios.parents(".btn-group");
                if (sortMenu.val() === "") { // relevance/no sort
                    directionButtonGroup.hide();
                } else {
                    directionButtonGroup.show();
                }
            };
            sortMenu.on("change", function() {
                showOrHideDirectionRadios();
                refreshResults();
            });
            directionRadios.on("change", function() {
                refreshResults();
            });
            showOrHideDirectionRadios();
            attachResultsEventListeners();
            refreshResults();
        });
    }).trigger("show.bs.tab");

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
                    const canvas    = $("#chart");
                    const chartData = $.parseJSON($("#chart-data").val());
                    new IDEALS.Chart(canvas, chartData);
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
            $('.edit-administrators').on("click", function () {
                const url = ROOT_URL + "/units/" + unitID + "/edit-administrators";
                $.get(url, function (data) {
                    $("#edit-administrators-modal .modal-body").html(data);
                    new IDEALS.LocalUserAutocompleter(
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
