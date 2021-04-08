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
            $("#items-tab-content").html(data);
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
            $('.edit-collection-access').on("click", function() {
                const url = ROOT_URL + "/collections/" + collectionID + "/edit-access";
                $.get(url, function(data) {
                    $("#edit-collection-access-modal .modal-body").html(data);
                    new IDEALS.UserAutocompleter(
                        $("input[name='managers[]'], input[name='submitters[]']"));
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
