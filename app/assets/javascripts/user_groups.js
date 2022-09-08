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
 * Handles list-user-groups views (/user-groups and /global-user-groups).
 *
 * @constructor
 */
const UserGroupsView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    $("#add-user-group-modal").on("show.bs.modal", function() {
        const url = ROOT_URL + "/user-groups/new";
        $.get(url, function(data) {
            const modalBody = $("#add-user-group-modal .modal-body");
            modalBody.html(data);
            if (window.location.href.match(/global-user-groups/)) {
                modalBody.find("input[name='user_group[institution_id]']").val("");
            }
            UserGroupForm.attachEventListeners();
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
            UserGroupForm.attachEventListeners();
        });
    });
    $("button.edit-ad-groups").on("click", function() {
        const id = $(this).data("user-group-id");
        const url = ROOT_URL + "/user-groups/" + id + "/edit-ad-groups";
        $.get(url, function(data) {
            $("#edit-ad-groups-modal .modal-body").html(data);
            UserGroupForm.attachEventListeners();
        });
    });
    $("button.edit-affiliations").on("click", function() {
        const id = $(this).data("user-group-id");
        const url = ROOT_URL + "/user-groups/" + id + "/edit-affiliations";
        $.get(url, function(data) {
            $("#edit-affiliations-modal .modal-body").html(data);
        });
    });
    $("button.edit-departments").on("click", function() {
        const id = $(this).data("user-group-id");
        const url = ROOT_URL + "/user-groups/" + id + "/edit-departments";
        $.get(url, function(data) {
            $("#edit-departments-modal .modal-body").html(data);
            UserGroupForm.attachEventListeners();
        });
    });
    $("button.edit-local-users").on("click", function() {
        const id = $(this).data("user-group-id");
        const url = ROOT_URL + "/user-groups/" + id + "/edit-local-users";
        $.get(url, function(data) {
            $("#edit-local-users-modal .modal-body").html(data);
        });
    });
    $("button.edit-netid-users").on("click", function() {
        const id = $(this).data("user-group-id");
        const url = ROOT_URL + "/user-groups/" + id + "/edit-netid-users";
        $.get(url, function(data) {
            $("#edit-netid-users-modal .modal-body").html(data);
            UserGroupForm.attachEventListeners();
        });
    });
    $("button.edit-hosts").on("click", function() {
        const id = $(this).data("user-group-id");
        const url = ROOT_URL + "/user-groups/" + id + "/edit-hosts";
        $.get(url, function(data) {
            $("#edit-hosts-modal .modal-body").html(data);
            UserGroupForm.attachEventListeners();
        });
    });
    $("button.edit-email-patterns").on("click", function() {
        const id = $(this).data("user-group-id");
        const url = ROOT_URL + "/user-groups/" + id + "/edit-email-patterns";
        $.get(url, function(data) {
            $("#edit-email-patterns-modal .modal-body").html(data);
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
