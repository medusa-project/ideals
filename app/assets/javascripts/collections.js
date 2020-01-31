/**
 * @constructor
 */
const CollectionsView = function() {

    const ROOT_URL = $('input[name="root_url"]').val();

    $('button.edit-collection').on('click', function() {
        var id = $(this).data('collection-id');
        var url = ROOT_URL + '/collections/' + id + '/edit';
        $.get(url, function(data) {
            $('#edit-collection-modal .modal-body').html(data);
        });
    });
    $('a[disabled="disabled"]').on('click', function() {
        return false;
    });

};

var ready = function() {
    if ($('body#show_collection').length) {
        new CollectionsView();
    }
};

$(document).ready(ready);
