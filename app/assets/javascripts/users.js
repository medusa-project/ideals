/**
 * Handles list-users view.
 */
const UsersView = {

    initialize: function() {
        $("button.add-invitee").on("click", InviteesView.AddInviteeClickHandler);

        const filterDiv = $("#user-filter");

        const refreshUsers = function () {
            const form = filterDiv.find("form");
            $.ajax({
                method: "GET",
                url: form.attr("action"),
                data: form.serialize(),
                success: function (data) {
                    $("#users-list").html(data);
                },
                error: function (data, status, xhr) {
                }
            });
        };

        let timeout = null;
        filterDiv.find("input").on("keyup", function () {
            clearTimeout(timeout);
            timeout = setTimeout(function () {
                refreshUsers();
            }, IDEALS.UIUtils.KEY_DELAY);
        });

        filterDiv.find("select").on("change", function () {
            refreshUsers();
        });
    }

};

/**
 * Handles show-user view.
 */
const UserView = {

    initialize: function() {
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
            });
        }).trigger("show.bs.tab");

        $("#credentials-tab").on("show.bs.tab", function() {
            const url = ROOT_URL + "/users/" + userID + "/credentials";
            $.get(url, function (data) {
                $("#credentials-tab-content").html(data);
                $("button.change-password").on("click", function() {
                    const id = $(this).data("identity-id");
                    const url = ROOT_URL + "/identities/" + id + "/edit-password";
                    $.get(url, function(data) {
                        $("#change-password-modal .modal-body").html(data);
                    });
                });
                $("button.create-local-identity").on("click", function() {
                    const id = $(this).data("user-id");
                    const url = ROOT_URL + "/users/" + id + "/identities/new";
                    $.get(url, function(data) {
                        $("#create-local-identity-modal .modal-body").html(data);
                    });
                });
            });
        }).trigger("show.bs.tab");

        $("#logins-tab").on("show.bs.tab", function() {
            const url = ROOT_URL + "/users/" + userID + "/logins";
            $.get(url, function (data) {
                $("#logins-tab-content").html(data);
            });
        });

        $("#submittable-collections-tab").on("show.bs.tab", function() {
            const url = ROOT_URL + "/users/" + userID + "/submittable-collections";
            $.get(url, function (data) {
                $("#submittable-collections-tab-content").html(data);
            });
        });

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
                    container.html(IDEALS.UIUtils.Spinner());
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
                    timeout = setTimeout(refreshResults, IDEALS.UIUtils.KEY_DELAY);
                });

                const showOrHideDirectionRadios = function() {
                    const directionButtonGroup = directionRadios.parents(".btn-group");
                    if (sortMenu.val() === "") { // relevance/no sort
                        directionButtonGroup.hide();
                        directionRadios.filter(":first").prop("checked", true);
                    } else {
                        directionButtonGroup.show();
                    }
                };
                sortMenu.on("change", function() {
                    showOrHideDirectionRadios();
                    refreshResults();
                });
                directionRadios.on("change", function() {
                    $(this).parent().addClass("active");
                    $(this).parent().siblings().removeClass("active");
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
        });
    }

};

$(document).ready(function() {
    if ($("body#list_users").length) {
        UsersView.initialize();
    } else if ($("body#show_user").length) {
        UserView.initialize();
    }
});
