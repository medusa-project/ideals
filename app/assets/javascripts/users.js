/**
 * Handles list-users view.
 *
 * @constructor
 */
const UsersView = function() {
    const filterDiv = $("#user-filter");

    const refreshUsers = function() {
        const form = filterDiv.find("form");
        $.ajax({
            method: "GET",
            url:    form.attr("action"),
            data:   form.serialize(),
            success: function(data) {
                $("#users-list").html(data);
            },
            error: function(data, status, xhr) {
            }
        });
    };

    let timeout = null;
    filterDiv.find("input").on("keyup", function() {
        clearTimeout(timeout);
        timeout = setTimeout(function() {
            refreshUsers();
        }, IDEALS.KEY_DELAY);
    });

    filterDiv.find("select").on("change", function() {
        refreshUsers();
    });
};

/**
 * Handles show-user view.
 *
 * @constructor
 */
const UserView = function() {
    const ROOT_URL = $("input[name=root_url]").val();
    const userID   = $("[name=user_id]").val();

    $("#properties-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/users/" + userID + "/properties";
        $.get(url, function (data) {
            $("#properties-tab-content").html(data);
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
        });
    }).trigger("show.bs.tab");

    $("#privileges-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/users/" + userID + "/privileges";
        $.get(url, function (data) {
            $("#privileges-tab-content").html(data);
            $('button.edit-privileges').on("click", function() {
                const id = $(this).data("user-id");
                const url = ROOT_URL + "/users/" + id + "/edit-privileges";
                $.get(url, function(data) {
                    $("#edit-privileges-modal .modal-body").html(data);
                });
            });
        });
    }).trigger("show.bs.tab");

    $("#submittable-collections-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/users/" + userID + "/submittable-collections";
        $.get(url, function (data) {
            $("#submittable-collections-tab-content").html(data);
        });
    }).trigger("show.bs.tab");

    $("#submitted-items-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/users/" + userID + "/submitted-items";
        $.get(url, function (data) {
            const tabContent = $("#submitted-items-tab-content");
            tabContent.html(data);

            const filterField     = tabContent.find("input[name=q]");
            const sortMenu        = tabContent.find("select[name=sort]");
            const directionRadios = tabContent.find("input[name=direction]");

            const attachResultsEventListeners = function() {
                $(".page-link").on("click", function(e) {
                    e.preventDefault();
                    refreshResults($(this).attr("href"));
                });
            };

            const refreshResults = function (url) {
                const container = $("#items-xhr-content");
                container.html(IDEALS.Spinner());
                if (!url) {
                    url = ROOT_URL + "/users/" + userID + "/submitted-item-results";
                }
                $.ajax({
                    method:  "GET",
                    url:     url,
                    data:    filterField.parents("form").serialize(),
                    success: function(data) {
                        console.log(data);
                        container.html(data);
                        attachResultsEventListeners();
                    },
                    error:   function(data, status, xhr) {
                        console.log(data);
                        console.log(status);
                        console.log(xhr);
                    }
                });
            };

            let timeout = null;
            filterField.on("keyup", function() {
                clearTimeout(timeout);
                timeout = setTimeout(refreshResults, IDEALS.KEY_DELAY);
            });

            const showOrHideDirectionRadios = function() {
                const directionButtonGroup = directionRadios.parents(".btn-group");
                if (sortMenu.val() === "") { // relevance/no sort
                    directionButtonGroup.hide();
                } else {
                    directionButtonGroup.show();
                }
            };
            sortMenu.on("change", function() {
                showOrHideDirectionRadios();
                refreshResults();
            });
            directionRadios.on("change", function() {
                refreshResults();
            });
            showOrHideDirectionRadios();
            attachResultsEventListeners();
            refreshResults();
        });
    });

    $("#submissions-in-progress-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/users/" + userID + "/submissions-in-progress";
        $.get(url, function (data) {
            $("#submissions-in-progress-tab-content").html(data);
        });
    }).trigger("show.bs.tab");

};

$(document).ready(function() {
    if ($("body#list_users").length) {
        new UsersView();
    } else if ($("body#show_user").length) {
        new UserView();
    }
});
