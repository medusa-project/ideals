/**
 * Handles list-user-groups view (/user-groups).
 *
 * @constructor
 */
const UserGroupsView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    $("button.edit-user-group").on("click", function() {
        const id = $(this).data("user-group-id");
        const url = ROOT_URL + "/user-groups/" + id + "/edit";
        $.get(url, function(data) {
            $("#edit-user-group-modal .modal-body").html(data);
        });
    });
};

/**
 * Handles show-user-group view (/user-groups/:id).
 *
 * @constructor
 */
const UserGroupView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    $("button.edit-user-group").on("click", function() {
        const id = $(this).data("user-group-id");
        const url = ROOT_URL + "/user-groups/" + id + "/edit";
        $.get(url, function(data) {
            $("#edit-user-group-modal .modal-body").html(data);
        });
    });

};

$(document).ready(function() {
    if ($("body#user_groups").length) {
        new UserGroupsView();
    } else if ($("body#show_user_group").length) {
        new UserGroupView();
    }
});
