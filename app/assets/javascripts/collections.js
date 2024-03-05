/**
 * Handles show-collection view.
 */
const CollectionView = {

    initialize: function() {
        const ROOT_URL      = $('input[name="root_url"]').val();
        const collectionID  = $("[name=collection_id]").val();
        const primaryUnitID = $("[name=primary_unit_id]").val();
        const institutionID = $("[name=institution_id]").val();

        $("#about-tab").on("show.bs.tab", function() {
            const url = ROOT_URL + "/collections/" + collectionID + "/about";
            $.get(url, function (data) {
                $("#about-tab-content").html(data);
                $('.edit-collection-properties').on("click", function() {
                    const url = ROOT_URL + "/collections/" + collectionID + "/edit-properties";
                    $.get(url, function(data) {
                        $("#edit-collection-properties-modal .modal-body").html(data);
                    });
                });
                $('.edit-unit-membership').on("click", function() {
                    const url = ROOT_URL + "/collections/" + collectionID + "/edit-unit-membership";
                    $.get(url, function(data) {
                        $("#edit-unit-membership-modal .modal-body").html(data);
                        new IDEALS.UIUtils.MultiElementList(0);
                    });
                });
                $('.edit-collection-membership').on("click", function() {
                    const url = ROOT_URL + "/collections/" + collectionID + "/edit-collection-membership";
                    $.get(url, function(data) {
                        $("#edit-collection-membership-modal .modal-body").html(data);
                        new IDEALS.UIUtils.MultiElementList(0);
                    });
                });
                $('.add-subcollection').on("click", function() {
                    const url = ROOT_URL + "/collections/new" +
                        "?collection%5Binstitution_id%5D=" + institutionID +
                        "&collection%5Bparent_id%5D=" + collectionID +
                        "&primary_unit_id=" + primaryUnitID;
                    $.get(url, function(data) {
                        $("#add-collection-modal .modal-body").html(data);
                    });
                });
            });
        });

        $("#items-tab").on("show.bs.tab", function() {
            const url = ROOT_URL + "/collections/" + collectionID + "/items";
            $.get(url, function (data) {
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
                        url = ROOT_URL + "/collections/" + collectionID + "/item-results";
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

                $(".download-files").on("click", function() {
                    const modal         = $("#download-files-modal")
                    const collection_id = $(this).data("collection-id");
                    // Initiate the download on the server. This will redirect to a
                    // download status page which will get inserted into the modal body.
                    const url = "/collections/" + collection_id + "/all-files.zip";
                    $.get(url, function(data) {
                        new IDEALS.UIUtils.DownloadPanel(modal, data);
                    });
                });

                $(".download-csv").on("click", function() {
                    const modal         = $("#download-csv-modal")
                    const collection_id = $(this).data("collection-id");
                    // Initiate the download on the server. This will redirect to a
                    // download status page which will get inserted into the modal body.
                    const url = "/collections/" + collection_id + "/items.csv";
                    $.get(url, function(data) {
                        new IDEALS.UIUtils.DownloadPanel(modal, data);
                    });
                });

                showOrHideDirectionRadios();
                attachResultsEventListeners();
                refreshResults();
            });
        }).trigger("show.bs.tab");

        $("#review-submissions-tab").on("show.bs.tab", function() {
            const url = ROOT_URL + "/collections/" + collectionID + "/review-submissions";
            $.get(url, function (data) {
                $("#review-submissions-tab-content").html(data);

                new IDEALS.UIUtils.CheckAllButton($('.check-all'),
                    $('#review-form input[type=checkbox]'));

                const form = $('form#review-form');
                const verb = form.find("[name=verb]");
                $('.approve-checked').on('click', function() {
                    verb.val("approve");
                    form.submit();
                });
                $('.reject-checked').on('click', function() {
                    verb.val("reject");
                    form.submit();
                });
            });
        });

        $("#submissions-in-progress-tab").on("show.bs.tab", function() {
            const url = ROOT_URL + "/collections/" + collectionID + "/submissions-in-progress";
            $.get(url, function(data) {
                $("#submissions-in-progress-tab-content").html(data);
            });
        });

        $("#statistics-tab").on("show.bs.tab", function() {
            const url = ROOT_URL + "/collections/" + collectionID + "/statistics";
            $.get(url, function(data) {
                const statsTabContent = $("#statistics-tab-content");
                statsTabContent.html(data);

                const refreshStatisticsByMonth = function() {
                    const innerTabContent = $("#statistics-by-month-tab-content");
                    innerTabContent.html(IDEALS.UIUtils.Spinner());
                    const url = ROOT_URL + "/collections/" + collectionID + "/statistics-by-range?" +
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
                    const url = ROOT_URL + "/collections/" + collectionID + "/item-download-counts?" +
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
            const url = ROOT_URL + "/collections/" + collectionID + "/access";
            $.get(url, function (data) {
                $("#access-tab-content").html(data);
                $(".edit-administering-groups").on("click", function() {
                    const url = ROOT_URL + "/collections/" + collectionID + "/edit-administering-groups";
                    $.get(url, function(data) {
                        $("#edit-administering-groups-modal .modal-body").html(data);
                    });
                });
                $(".edit-administering-users").on("click", function() {
                    const url = ROOT_URL + "/collections/" + collectionID + "/edit-administering-users";
                    $.get(url, function(data) {
                        $("#edit-administering-users-modal .modal-body").html(data);
                        new IDEALS.UIUtils.UserAutocompleter($("input[name='administrators[]']"), true);
                        new IDEALS.UIUtils.MultiElementList();
                    });
                });
                $(".edit-submitting-groups").on("click", function() {
                    const url = ROOT_URL + "/collections/" + collectionID + "/edit-submitting-groups";
                    $.get(url, function(data) {
                        $("#edit-submitting-groups-modal .modal-body").html(data);
                    });
                });
                $(".edit-submitting-users").on("click", function() {
                    const url = ROOT_URL + "/collections/" + collectionID + "/edit-submitting-users";
                    $.get(url, function(data) {
                        $("#edit-submitting-users-modal .modal-body").html(data);
                        new IDEALS.UIUtils.UserAutocompleter($("input[name='submitters[]']"), true);
                        new IDEALS.UIUtils.MultiElementList();
                    });
                });
            });
        });
    }
};

$(document).ready(function() {
    if ($("body#show_collection").length) {
        CollectionView.initialize();
    }
});
