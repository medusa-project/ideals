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

    // Downloads tab
    const downloads_content = $("#downloads-xhr-content");
    const refreshDownloads = function(id) {
        const url = ROOT_URL + "/collections/" + id + "/downloads?" +
            $("#downloads-tab-content form").serialize();
        $.get(url, function(data) {
            downloads_content.prev().hide(); // hide the spinner
            downloads_content.html(data);
        });
    };

    const downloads_tab = $('#downloads-tab');
    downloads_tab.on('show.bs.tab', function() {
        const id = $(this).data("collection-id");
        refreshDownloads(id);
    });
    $("#downloads-tab-content input[type=submit]").on("click", function() {
        // Remove existing content and show the spinner
        downloads_content.empty();
        downloads_content.prev().show(); // show the spinner

        const id = downloads_tab.data("collection-id");
        refreshDownloads(id);
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
