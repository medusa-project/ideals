const UserGroupForm = {
    attachEventListeners: function() {
        $('button.remove').on('click', function () {
            const row = $(this).closest('.input-group');
            const siblings = row.siblings('.input-group');
            if (siblings.length > 0) {
                row.remove();
            } else {
                row.find('input').val('');
            }
            return false;
        });
        $('button.add').on('click', function () {
            const lastRow = $(this).closest('form').find('.input-group:last');
            const clone = lastRow.clone(true);
            clone.find('input[type=text]').val('');
            lastRow.after(clone);
            return false;
        });
    }
}

/**
 * Handles list-user-groups view (/user-groups).
 *
 * @constructor
 */
const UserGroupsView = function() {
    $("#add-user-group-modal").on("show.bs.modal", function() {
        UserGroupForm.attachEventListeners();
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
            UserGroupForm.attachEventListeners();
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
