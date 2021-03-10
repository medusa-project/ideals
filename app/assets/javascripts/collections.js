/**
 * Handles show-collection view.
 *
 * @constructor
 */
const CollectionView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    // Review Submissions tab
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

    // Statistics tab
    const statistics_content = $("#statistics-xhr-content");
    const refreshStatistics = function(id) {
        const url = ROOT_URL + "/collections/" + id + "/statistics?" +
            $("#statistics-tab-content form").serialize();
        $.get(url, function(data) {
            statistics_content.prev().hide(); // hide the spinner
            statistics_content.html(data);
        });
    };

    const statistics_tab = $('#statistics-tab');
    statistics_tab.on('show.bs.tab', function() {
        const id = $(this).data("collection-id");
        refreshStatistics(id);
    });
    $("#statistics-tab-content input[type=submit]").on("click", function() {
        // Remove existing content and show the spinner
        statistics_content.empty();
        statistics_content.prev().show(); // show the spinner

        const id = statistics_tab.data("collection-id");
        refreshStatistics(id);
        return false;
    });

    $('.edit-collection-access').on("click", function() {
        const id = $(this).data("collection-id");
        const url = ROOT_URL + "/collections/" + id + "/edit-access";
        $.get(url, function(data) {
            $("#edit-collection-access-modal .modal-body").html(data);
            new IDEALS.UserAutocompleter(
                $("input[name='managers[]'], input[name='submitters[]']"));
            new IDEALS.MultiElementList();
        });
    });
    $('.edit-collection-membership').on("click", function() {
        const id = $(this).data("collection-id");
        const url = ROOT_URL + "/collections/" + id + "/edit-collection-membership";
        $.get(url, function(data) {
            $("#edit-collection-membership-modal .modal-body").html(data);
            new IDEALS.MultiElementList(0);
        });
    });
    $('.edit-collection-properties').on("click", function() {
        const id = $(this).data("collection-id");
        const url = ROOT_URL + "/collections/" + id + "/edit-properties";
        $.get(url, function(data) {
            $("#edit-collection-properties-modal .modal-body").html(data);
        });
    });
    $('.edit-unit-membership').on("click", function() {
        const id = $(this).data("collection-id");
        const url = ROOT_URL + "/collections/" + id + "/edit-unit-membership";
        $.get(url, function(data) {
            $("#edit-unit-membership-modal .modal-body").html(data);
            new IDEALS.MultiElementList(0);
        });
    });
};

$(document).ready(function() {
    if ($('body#show_collection').length) {
        new CollectionView();
    }
});
