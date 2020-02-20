/**
 * Handles list-users view.
 *
 * @constructor
 */
const UsersView = function() {
    // Select the authentication type based on the URL "class" argument, as the
    // browser won't do this automatically.
    const queryArgs = new URLSearchParams(location.search);
    if (queryArgs.has("class")) {
        $("select[name=class]").val(queryArgs.get("class"));
    }
};

/**
 * Handles show-user view.
 *
 * @constructor
 */
const UserView = function() {

    const ROOT_URL = $('input[name="root_url"]').val();

    $('button.edit-user').on('click', function() {
        var id = $(this).data('user-id');
        var url = ROOT_URL + '/users/' + id + '/edit';
        $.get(url, function(data) {
            $('#edit-user-modal .modal-body').html(data);
        });
    });

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
