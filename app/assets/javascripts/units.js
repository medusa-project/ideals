/**
 * Handles list-units view.
 */
const UnitsView = {

    AddUnitClickHandler: function () {
        const institutionID = $("[name=institution_id]").val();
        const url = "/units/new?unit%5Binstitution_id%5D=" + institutionID;
        $.get(url, function (data) {
            $("#add-unit-modal .modal-body").html(data);
        });
    },

    initialize: function () {
        new IDEALS.UIUtils.ExpandableResourceList();
        new IDEALS.UIUtils.UserAutocompleter(
            $("input[name=primary_administrator], input[name='administering_users[]']"),
            true);
        new IDEALS.UIUtils.MultiElementList();

        $(".add-unit").on("click", UnitsView.AddUnitClickHandler);
    }

}

/**
 * Handles show-unit view.
 */
const UnitView = {

    initialize: function() {
        const ROOT_URL      = $('input[name="root_url"]').val();
        const institutionID = $("[name=institution_id]").val();
        const unitID        = $("[name=unit_id]").val();

        $("#about-tab").on("show.bs.tab", function() {
            const url = ROOT_URL + "/units/" + unitID + "/about";
            $.get(url, function(data) {
                $("#about-tab-content").html(data);
                $('.edit-unit-properties').on("click", function() {
                    const url = ROOT_URL + "/units/" + unitID + "/edit-properties";
                    $.get(url, function(data) {
                        $("#edit-unit-properties-modal .modal-body").html(data);
                    });
                });
                $(".add-child-unit").on("click", function() {
                    const url = "/units/new?unit%5Binstitution_id%5D=" + institutionID +
                        "&unit%5Bparent_id%5D=" + unitID;
                    $.get(url, function(data) {
                        $("#add-child-unit-modal .modal-body").html(data);
                    });
                });
                $('.edit-unit-membership').on("click", function () {
                    const url = ROOT_URL + "/units/" + unitID + "/edit-membership";
                    $.get(url, function (data) {
                        $("#edit-unit-membership-modal .modal-body").html(data);
                    });
                });
                $('.add-collection').on("click", function() {
                    const url = ROOT_URL + "/collections/new" +
                        "?collection%5Binstitution_id%5D=" + institutionID +
                        "&primary_unit_id=" + unitID;
                    $.get(url, function(data) {
                        $("#add-collection-modal .modal-body").html(data);
                    });
                });
            });
        });

        $("#collections-tab").on("show.bs.tab", function() {
            const url = ROOT_URL + "/units/" + unitID + "/collections";
            $.get(url, function(data) {
                $("#collections-tab-content").html(data);
                $('.add-collection').on("click", function() {
                    const url = ROOT_URL + "/collections/new" +
                        "?collection%5Binstitution_id%5D=" + institutionID +
                        "&primary_unit_id=" + unitID;
                    $.get(url, function(data) {
                        $("#add-collection-modal .modal-body").html(data);
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
                    container.html(IDEALS.UIUtils.Spinner());
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
                    }, IDEALS.UIUtils.KEY_DELAY);
                });
                searchControls.on("change", function() {
                    refreshResults();
                });
                // When the search-type tab is changed, clear the input from all
                // sibling tabs.
                tabContent.find('#search-tabs > li > a[data-bs-toggle="pill"]').on('hidden.bs.tab', function(e) {
                    const hiddenPane = $($(e.target).attr("href"));
                    hiddenPane.find("input[type=text], input[type=search], textarea").val("");
                    hiddenPane.find("select > option:first-child").prop("selected", "selected");
                    searchControls.trigger("change");
                });
                // When a date search type tab is changed, clear the input from
                // the hidden tab.
                tabContent.find('.date-search-type > li > a[data-bs-toggle="pill"]').on('hidden.bs.tab', function(e) {
                    const hiddenPane = $($(e.target).attr("href"));
                    hiddenPane.find("select > option:first-child").prop("selected", "selected");
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
                    innerTabContent.html(IDEALS.UIUtils.Spinner());
                    const url = ROOT_URL + "/units/" + unitID + "/statistics-by-range?" +
                        statsTabContent.find("form").serialize();
                    $.ajax({
                        method: "GET",
                        url:    url,
                        success: function(data) {
                            $("#error-flash").hide();
                            innerTabContent.html(data);
                            const canvas    = $("#chart");
                            const chartData = $.parseJSON($("#chart-data").val());
                            const color     = $("[name=chart_color]").val();
                            new IDEALS.UIUtils.Chart(canvas, chartData, color);
                        },
                        error: function(data, status, xhr) {
                            $("#error-flash").text(data.responseText).show();
                        }
                    });
                };
                const refreshDownloadsByItem = function() {
                    const innerTabContent = $("#downloads-by-item-tab-content");
                    innerTabContent.html(IDEALS.UIUtils.Spinner());
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
                $(".edit-administering-groups").on("click", function () {
                    const url = ROOT_URL + "/units/" + unitID + "/edit-administering-groups";
                    $.get(url, function (data) {
                        $("#edit-administering-groups-modal .modal-body").html(data);
                    });
                });
                $(".edit-administering-users").on("click", function () {
                    const url = ROOT_URL + "/units/" + unitID + "/edit-administering-users";
                    $.get(url, function (data) {
                        $("#edit-administering-users-modal .modal-body").html(data);
                        new IDEALS.UIUtils.UserAutocompleter(
                            $("input[name=primary_administrator], input[name='administering_users[]']"), true);
                        new IDEALS.UIUtils.MultiElementList();
                    });
                });
            });
        });

        $("#review-submissions-tab").on("show.bs.tab", function() {
            const url = ROOT_URL + "/units/" + unitID + "/review-submissions";
            $.get(url, function (data) {
                $("#review-submissions-tab-content").html(data);

                new IDEALS.UIUtils.CheckAllButton($(".check-all"),
                    $('#review-form input[type=checkbox]'));

                const form = $("form#review-form");
                const verb = form.find("[name=verb]");
                $(".approve-checked").on('click', function() {
                    verb.val("approve");
                    form.submit();
                });
                $(".reject-checked").on('click', function() {
                    verb.val("reject");
                    form.submit();
                });
            });
        });

        $("#submissions-in-progress-tab").on("show.bs.tab", function() {
            const url = ROOT_URL + "/units/" + unitID + "/submissions-in-progress";
            $.get(url, function(data) {
                $("#submissions-in-progress-tab-content").html(data);
            });
        });
    }

};

$(document).ready(function() {
    if ($("body#list_units").length) {
        UnitsView.initialize();
    } else if ($("body#show_unit").length) {
        UnitView.initialize();
    }
});
