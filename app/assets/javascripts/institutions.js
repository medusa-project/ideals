/**
 * Handles show-institution view (/institutions/:key).
 *
 * @constructor
 */
const InstitutionView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();
    const institutionKey = $("[name=institution_key]").val();

    $("#preservation-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/institutions/" + institutionKey + "/preservation";
        $.get(url, function (data) {
            $("#preservation-tab-content").html(data);
            $('button.edit-preservation').on("click", function() {
                const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-preservation";
                $.get(url, function(data) {
                    $("#edit-preservation-modal .modal-body").html(data);
                });
            });
        });
    }).trigger("show.bs.tab");

    $("#properties-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/institutions/" + institutionKey + "/properties";
        $.get(url, function (data) {
            $("#properties-tab-content").html(data);
            $('button.edit-properties').on("click", function() {
                const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-properties";
                $.get(url, function(data) {
                    $("#edit-properties-modal .modal-body").html(data);
                });
            });
        });
    }).trigger("show.bs.tab");

    $("#settings-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/institutions/" + institutionKey + "/settings";
        $.get(url, function (data) {
            $("#settings-tab-content").html(data);
            $('button.edit-settings').on("click", function() {
                const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-settings";
                $.get(url, function(data) {
                    $("#edit-settings-modal .modal-body").html(data);
                });
            });
        });
    }).trigger("show.bs.tab");

    $("#theme-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/institutions/" + institutionKey + "/theme";
        $.get(url, function (data) {
            $("#theme-tab-content").html(data);
            $('button.edit-theme').on("click", function() {
                const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-theme";
                $.get(url, function(data) {
                    $("#edit-theme-modal .modal-body").html(data);
                });
            });
        });
    }).trigger("show.bs.tab");

    $("#users-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/institutions/" + institutionKey + "/users";
        $.get(url, function (data) {
            $("#users-tab-content").html(data);
        });
    }).trigger("show.bs.tab");

    $("#statistics-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/institutions/" + institutionKey + "/statistics";
        $.get(url, function(data) {
            const statsTabContent = $("#statistics-tab-content");
            statsTabContent.html(data);

            const refreshStatisticsByMonth = function() {
                const innerTabContent = $("#statistics-by-month-tab-content");
                innerTabContent.html(IDEALS.Spinner());
                const url = ROOT_URL + "/institutions/" + institutionKey + "/statistics-by-range?" +
                    statsTabContent.find("form").serialize();
                $.ajax({
                    method: "GET",
                    url:    url,
                    success: function(data) {
                        $("#error-flash").hide();
                        innerTabContent.html(data);
                    },
                    error: function(data, status, xhr) {
                        $("#error-flash").text(data.responseText).show();
                    }
                });
            };
            const refreshDownloadsByItem = function() {
                const innerTabContent = $("#downloads-by-item-tab-content");
                innerTabContent.html(IDEALS.Spinner());
                const url = ROOT_URL + "/institutions/" + institutionKey + "/item-download-counts?" +
                    statsTabContent.find("form").serialize();
                $.get(url, function (data) {
                    innerTabContent.html(data);
                });
            };

            $("#statistics-by-month-tab").on("show.bs.tab", function() {
                refreshStatisticsByMonth()
            }).trigger("show.bs.tab");
            $("#downloads-by-item-tab").on("show.bs.tab", function() {
                refreshDownloadsByItem();
            });

            statsTabContent.find("input[type=submit]").on("click", function () {
                const activeSubTabContent = statsTabContent.find(".tab-content .active");
                switch (activeSubTabContent.prop("id")) {
                    case "statistics-by-month-tab-content":
                        refreshStatisticsByMonth();
                        break;
                    case "downloads-by-item-tab-content":
                        refreshDownloadsByItem();
                        break;
                }
                return false;
            });
        });
    });

    $("#access-tab").on("show.bs.tab", function() {
        const url = ROOT_URL + "/institutions/" + institutionKey + "/access";
        $.get(url, function(data) {
            $("#access-tab-content").html(data);

            $('.invite-administrator').on("click", function () {
                const url = ROOT_URL + "/institutions/" + institutionKey + "/invite-administrator";
                $.get(url, function (data) {
                    $("#invite-administrator-modal .modal-body").html(data);
                });
            });
            $('.edit-administrators').on("click", function () {
                const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-administrators";
                $.get(url, function (data) {
                    $("#edit-administrators-modal .modal-body").html(data);
                    new IDEALS.LocalUserAutocompleter(
                        $("input[name=primary_administrator], input[name='administering_users[]']"));
                    new IDEALS.MultiElementList();
                });
            });
        });
    });
};

$(document).ready(function() {
    if ($('body#show_institution').length) {
        new InstitutionView();
    }
});
