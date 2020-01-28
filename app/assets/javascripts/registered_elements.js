/**
 * @constructor
 */
const RegisteredElementsView = function() {

    const ROOT_URL = $('input[name="root_url"]').val();

    $('button.edit-element').on('click', function() {
        var element_name = $(this).data('element-name');
        var url = ROOT_URL + '/elements/' + element_name + '/edit';
        $.get(url, function(data) {
            $('#edit-element-modal .modal-body').html(data);
        });
    });
    $('a[disabled="disabled"]').on('click', function() {
        return false;
    });

};

var ready = function() {
    if ($('body#registered_elements').length) {
        new RegisteredElementsView();
    }
};

$(document).ready(ready);
