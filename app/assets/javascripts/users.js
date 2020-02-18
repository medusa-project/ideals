/**
 * Handles list-users view.
 *
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

};

/**
 * Handles show-user view.
 *
 * @constructor
 */
const UserView = function() {

    const queryArgs = new URLSearchParams(window.location.search);
    if (queryArgs.has("start")) {
        $("#items-tab").tab("show");
    }

};

$(document).ready(function() {
    if ($("body#users_index").length) {
        new UsersView();
    } else if ($("body#show_user").length) {
        new UserView();
    }
});
