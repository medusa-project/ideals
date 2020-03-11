/**
 * Handles list-collections view.
 *
 * @constructor
 */
const CollectionsView = function() {
    new IDEALS.FacetSet().init();
};

/**
 * Handles show-collection view.
 *
 * @constructor
 */
const CollectionView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

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
        const url = ROOT_URL + "/collections/" + id + "/edit-membership";
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

};

$(document).ready(function() {
    if ($("body#list_collections").length) {
        new CollectionsView();
    } else if ($('body#show_collection').length) {
        new CollectionView();
    }
});
