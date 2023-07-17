const UserGroups = {
    AddUserGroupClickHandler: function() {
        const ROOT_URL      = $('input[name="root_url"]').val();
        const institutionID = $("input[name=institution_id]").val();
        const url           = ROOT_URL + "/user-groups/new?" +
            "user_group%5Binstitution_id%5D=" + institutionID;
        $.get(url, function(data) {
            const modalBody = $("#add-user-group-modal .modal-body");
            modalBody.html(data);
            if (window.location.href.match(/global-user-groups/)) {
                modalBody.find("input[name='user_group[institution_id]']").val("");
            }
            UserGroupForm.attachEventListeners();
        });
    }
};

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
    $("#add-user-group-modal").on("show.bs.modal",
        UserGroups.AddUserGroupClickHandler);
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
    $("button.edit-users").on("click", function() {
        const id     = $(this).data("user-group-id");
        const scoped = !$(this).data("user-group-global");
        const url    = ROOT_URL + "/user-groups/" + id + "/edit-users";
        $.get(url, function(data) {
            $("#edit-users-modal .modal-body").html(data);
            UserGroupForm.attachEventListeners();
            new IDEALS.UIUtils.UserAutocompleter($("input[name='user_group[users][]']"),
                                                 scoped);
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
