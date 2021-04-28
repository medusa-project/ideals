/**
 * Handles show-collection view.
 *
 * @constructor
 */
const CollectionView = function() {
    const ROOT_URL     = $('input[name="root_url"]').val();
    const collectionID = $("[name=collection_id]").val();

    $("#properties-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/collections/" + collectionID + "/properties";
        $.get(url, function (data) {
            $("#properties-tab-content").html(data);
            $('.edit-collection-properties').on("click", function() {
                const url = ROOT_URL + "/collections/" + collectionID + "/edit-properties";
                $.get(url, function(data) {
                    $("#edit-collection-properties-modal .modal-body").html(data);
                });
            });
        });
    }).trigger("show.bs.tab");

    $("#units-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/collections/" + collectionID + "/units";
        $.get(url, function(data) {
            $("#units-tab-content").html(data);
            $('.edit-unit-membership').on("click", function() {
                const url = ROOT_URL + "/collections/" + collectionID + "/edit-unit-membership";
                $.get(url, function(data) {
                    $("#edit-unit-membership-modal .modal-body").html(data);
                    new IDEALS.MultiElementList(0);
                });
            });
        });
    });

    $("#collections-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/collections/" + collectionID + "/collections";
        $.get(url, function (data) {
            $("#collections-tab-content").html(data);
            $('.edit-collection-membership').on("click", function() {
                const url = ROOT_URL + "/collections/" + collectionID + "/edit-collection-membership";
                $.get(url, function(data) {
                    $("#edit-collection-membership-modal .modal-body").html(data);
                    new IDEALS.MultiElementList(0);
                });
            });
        });
    });

    $("#items-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/collections/" + collectionID + "/items";
        $.get(url, function (data) {
            const tabContent = $("#items-tab-content");
            tabContent.html(data);

            const filterField = tabContent.find("input[name=q]");
            const sortMenu    = tabContent.find("select[name=sort]");

            const refreshResults = function () {
                $("#items-xhr-content").html(IDEALS.Spinner());
                $.ajax({
                    method: "GET",
                    url: ROOT_URL + "/collections/" + collectionID + "/item-results",
                    data: filterField.parents("form").serialize(),
                    success: function(data) {
                        $("#items-xhr-content").html(data);
                    },
                    error: function(data, status, xhr) {
                        console.log(data);
                        console.log(status);
                        console.log(xhr);
                    }
                });
            };

            let timeout = null;
            filterField.on("keyup", function() {
                clearTimeout(timeout);
                timeout = setTimeout(refreshResults, IDEALS.KEY_DELAY);
            });
            sortMenu.on("change", function() {
                refreshResults();
            });
        });
    });

    $("#review-submissions-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/collections/" + collectionID + "/review-submissions";
        $.get(url, function (data) {
            $("#review-submissions-tab-content").html(data);

            new IDEALS.CheckAllButton($('.check-all'),
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

    $("#statistics-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/collections/" + collectionID + "/statistics";
        $.get(url, function(data) {
            const statsTabContent = $("#statistics-tab-content");
            statsTabContent.html(data);

            const refreshStatisticsByMonth = function() {
                const innerTabContent = $("#statistics-by-month-tab-content");
                innerTabContent.html(IDEALS.Spinner());
                const url = ROOT_URL + "/collections/" + collectionID + "/statistics-by-range?" +
                    statsTabContent.find("form").serialize();
                $.get(url, function (data) {
                    innerTabContent.html(data);
                });
            };
            const refreshDownloadsByItem = function() {
                const innerTabContent = $("#downloads-by-item-tab-content");
                innerTabContent.html(IDEALS.Spinner());
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
            $('.edit-collection-managers').on("click", function() {
                const url = ROOT_URL + "/collections/" + collectionID + "/edit-managers";
                $.get(url, function(data) {
                    $("#edit-collection-managers-modal .modal-body").html(data);
                    new IDEALS.UserAutocompleter($("input[name='managers[]']"));
                    new IDEALS.MultiElementList();
                });
            });
            $('.edit-collection-submitters').on("click", function() {
                const url = ROOT_URL + "/collections/" + collectionID + "/edit-submitters";
                $.get(url, function(data) {
                    $("#edit-collection-submitters-modal .modal-body").html(data);
                    new IDEALS.UserAutocompleter($("input[name='submitters[]']"));
                    new IDEALS.MultiElementList();
                });
            });
        });
    });
};

$(document).ready(function() {
    if ($('body#show_collection').length) {
        new CollectionView();
    }
});
