/**
 * @constructor
 */
const UnitsView = function() {

    const ROOT_URL = $('input[name="root_url"]').val();

    $('button.edit-unit').on('click', function() {
        var id = $(this).data('unit-id');
        var url = ROOT_URL + '/units/' + id + '/edit';
        $.get(url, function(data) {
            $('#edit-unit-modal .modal-body').html(data);
        });
    });
    $('a[disabled="disabled"]').on('click', function() {
        return false;
    });

};

$(document).ready(function() {
    if ($('body#show_unit').length) {
        new UnitsView();
    }
});
