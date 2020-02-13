/**
 * @constructor
 */
const CollectionsView = function() {

    const ROOT_URL = $('input[name="root_url"]').val();

    $('.edit-collection-access').on("click", function() {
        const id = $(this).data("collection-id");
        const url = ROOT_URL + "/collections/" + id + "/edit-access";
        $.get(url, function(data) {
            $("#edit-collection-access-modal .modal-body").html(data);
        });
    });
    $('.edit-collection-membership').on("click", function() {
        const id = $(this).data("collection-id");
        const url = ROOT_URL + "/collections/" + id + "/edit-membership";
        $.get(url, function(data) {
            $("#edit-collection-membership-modal .modal-body").html(data);
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

var ready = function() {
    if ($('body#show_collection').length) {
        new CollectionsView();
    }
};

$(document).ready(ready);
