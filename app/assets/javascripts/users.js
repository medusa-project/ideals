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

    const ROOT_URL = $("input[name=root_url]").val();

    $('button.edit-privileges').on("click", function() {
        const id = $(this).data("user-id");
        const url = ROOT_URL + "/users/" + id + "/edit-privileges";
        $.get(url, function(data) {
            $("#edit-privileges-modal .modal-body").html(data);
        });
    });
    $("button.edit-properties").on("click", function() {
        const id = $(this).data("user-id");
        const url = ROOT_URL + "/users/" + id + "/edit-properties";
        $.get(url, function(data) {
            $("#edit-properties-modal .modal-body").html(data);
        });
    });
    $("button.change-password").on("click", function() {
        const id = $(this).data("identity-id");
        const url = ROOT_URL + "/identities/" + id + "/edit-password";
        $.get(url, function(data) {
            $("#change-password-modal .modal-body").html(data);
        });
    });

    const queryArgs = new URLSearchParams(window.location.search);
    if (queryArgs.has("start")) {
        $("#items-tab").tab("show");
    }

};

$(document).ready(function() {
    if ($("body#list_users").length) {
        new UsersView();
    } else if ($("body#show_user").length) {
        new UserView();
    }
});
