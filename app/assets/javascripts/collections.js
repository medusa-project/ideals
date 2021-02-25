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

    $('#statistics-tab').on('show.bs.tab', function (event) {
        const id = $(this).data("collection-id");
        const url = ROOT_URL + "/collections/" + id + "/statistics";
        $.get(url, function(data) {
            $("#statistics-tab-content").html(data);
        });
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
