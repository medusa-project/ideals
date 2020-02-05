/**
 * @constructor
 */
const UsersView = function() {

    const ROOT_URL = $('input[name="root_url"]').val();

    $('button.edit-user').on('click', function() {
        var id = $(this).data('user-id');
        var url = ROOT_URL + '/users/' + id + '/edit';
        $.get(url, function(data) {
            $('#edit-user-modal .modal-body').html(data);
        });
    });
    $('a[disabled="disabled"]').on('click', function() {
        return false;
    });

};

$(document).ready(function() {
    if ($('body#show_user').length) {
        new UsersView();
    }
});
