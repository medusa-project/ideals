/**
 * Handles list-institutions view (/institutions).
 */
const InstitutionsView = {

    initialize: function() {
        $("button.add-institution").on("click", function () {
            const ROOT_URL = $("input[name='root_url']").val();
            const url      = ROOT_URL + "/institutions/new";
            $.get(url, function (data) {
                $("#add-institution-modal .modal-body").html(data);
            });
        });
    }

};


/**
 * Handles show-institution view (/institutions/:key).
 */
const InstitutionView = {

    initialize: function() {
        const ROOT_URL       = $('input[name="root_url"]').val();
        const institutionKey = $("[name=institution_key]").val();

        $("#preservation-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/preservation";
            $.get(url, function (data) {
                $("#preservation-tab-content").html(data);
                $("button.edit-preservation").on("click", function () {
                    const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-preservation";
                    $.get(url, function (data) {
                        $("#edit-preservation-modal .modal-body").html(data);
                    });
                });
            });
        });

        $("#properties-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/properties";
            $.get(url, function (data) {
                $("#properties-tab-content").html(data);
                $("button.edit-properties").on("click", function () {
                    const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-properties";
                    $.get(url, function (data) {
                        $("#edit-properties-modal .modal-body").html(data);
                    });
                });
            });
        }).trigger("show.bs.tab");

        $("#settings-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/settings";
            $.get(url, function (data) {
                $("#settings-tab-content").html(data);
                $("button.edit-settings").on("click", function () {
                    const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-settings";
                    $.get(url, function (data) {
                        $("#edit-settings-modal .modal-body").html(data);
                    });
                });
            });
        });

        $("#authentication-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/authentication";
            $.get(url, function (data) {
                $("#authentication-tab-content").html(data);
                $("button.edit-local-authentication").on("click", function () {
                    const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-local-authentication";
                    $.get(url, function (data) {
                        const modalBody = $("#edit-local-authentication-modal .modal-body");
                        modalBody.html(data);
                    });
                });
                $("button.edit-saml-authentication").on("click", function () {
                    const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-saml-authentication";
                    $.get(url, function (data) {
                        const modalBody = $("#edit-saml-authentication-modal .modal-body");
                        modalBody.html(data);
                        const ssoFederationRadio = modalBody.find("input[name='institution[sso_federation]']");
                        const emailLocationMenu  = modalBody.find("select[name='institution[saml_email_location]']");

                        const onFederationRadioChanged = function (checkedRadio) {
                            if (parseInt(checkedRadio.val()) != 2) { // 2 = Institution::SSOFederation::NONE
                                $("[name='institution[saml_idp_sso_post_service_url]']").parent().hide();
                                $("[name='institution[saml_idp_sso_redirect_service_url]']").parent().hide();
                                $("[name='institution[saml_idp_entity_id]']").next("p").show();
                            } else {
                                $("[name='institution[saml_idp_sso_post_service_url]']").parent().show();
                                $("[name='institution[saml_idp_sso_redirect_service_url]']").parent().show();
                                $("[name='institution[saml_idp_entity_id]']").next("p").hide();
                            }
                        };
                        const onEmailLocationChanged = function (select) {
                            switch (select.val()) {
                                case "0": // NameID
                                    $("[name='institution[saml_email_attribute]']").parent().hide();
                                    break;
                                case "1": // Attribute
                                    $("[name='institution[saml_email_attribute]']").parent().show();
                                    break;
                            }
                        };
                        ssoFederationRadio.on("change", function () {
                            const checkedRadio = $("input[name='" + $(this).attr("name") + "']:checked");
                            onFederationRadioChanged(checkedRadio);
                        });
                        emailLocationMenu.on("change", function () {
                            onEmailLocationChanged($(this));
                        });
                        onFederationRadioChanged(ssoFederationRadio.filter(":checked"));
                        onEmailLocationChanged(emailLocationMenu);
                    });
                });
                $("button.supply-saml-configuration").on("click", function () {
                    const url = ROOT_URL + "/institutions/" + institutionKey + "/supply-saml-configuration";
                    $.get(url, function (data) {
                        const modalBody = $("#supply-saml-configuration-modal .modal-body");
                        modalBody.html(data);
                    });
                });
                $("button.edit-shibboleth-authentication").on("click", function () {
                    const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-shibboleth-authentication";
                    $.get(url, function (data) {
                        const modalBody = $("#edit-shibboleth-authentication-modal .modal-body");
                        modalBody.html(data);
                    });
                });
            });
        });

        $("#deleted-items-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/buried-items";
            $.get(url, function (data) {
                $("#deleted-items-tab-content").html(data);

                const attachResultsEventListeners = function() {
                    $(".page-link").on("click", function(e) {
                        e.preventDefault();
                        refreshResults($(this).attr("href"));
                    });
                };
                attachResultsEventListeners();

                const refreshResults = function(url) {
                    const container = $("#deleted-items-tab-content");
                    container.html(IDEALS.UIUtils.Spinner());
                    if (!url) {
                        url = ROOT_URL + "/institutions/" + institutionKey + "/buried-items";
                    }
                    $.ajax({
                        method:  "GET",
                        url:     url,
                        success: function(data) {
                            container.html(data);
                            attachResultsEventListeners();
                        }
                    });
                };
            });
        });

        $("#depositing-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/depositing";
            $.get(url, function (data) {
                $("#depositing-tab-content").html(data);
                $("button.edit-deposit-agreement").on("click", function () {
                    const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-deposit-agreement";
                    $.get(url, function (data) {
                        $("#edit-deposit-agreement-modal .modal-body").html(data);
                    });
                });
                $("button.edit-deposit-help").on("click", function () {
                    const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-deposit-help";
                    $.get(url, function (data) {
                        $("#edit-deposit-help-modal .modal-body").html(data);
                    });
                });
                $("button.edit-deposit-questions").on("click", function () {
                    const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-deposit-questions";
                    $.get(url, function (data) {
                        const modalBody = $("#edit-deposit-questions-modal .modal-body");
                        modalBody.html(data);

                        const updateQuestionIndices = function () {
                            modalBody.find(".question").each(function (qindex, question) {
                                $(question).find(".card-header h5").each(function () {
                                    $(this).text("Question " + (qindex + 1));
                                });
                                $(question).find("textarea").each(function (tindex, textarea) {
                                    const newName = $(textarea).attr("name")
                                        .replace(/questions\[[0-9]]/, "questions[" + qindex + "]");
                                    $(textarea).attr("name", newName);
                                });
                                $(question).find(".response").each(function (rindex, response) {
                                    $(response).find(".card-header h6").each(function () {
                                        $(this).text("Response " + (rindex + 1));
                                    });
                                    $(response).find("input").each(function () {
                                        const input = $(this);
                                        let newName = input.attr("name")
                                            .replace(/questions\[[0-9]]/, "questions[" + qindex + "]")
                                            .replace(/responses]\[[0-9]]/, "responses][" + rindex + "]");
                                        input.attr("name", newName);
                                        input.attr("id", newName);
                                    });
                                    $(response).find("label").each(function () {
                                        const label = $(this);
                                        let newFor = label.attr("for")
                                            .replace(/questions\[[0-9]]/, "questions[" + qindex + "]")
                                            .replace(/responses]\[[0-9]]/, "responses][" + rindex + "]");
                                        label.attr("for", newFor);
                                    });
                                });
                            });
                        };

                        const updateEventListeners = function () {
                            $("button.add-question, button.add-response").off("click").on("click", function (e) {
                                e.preventDefault();
                                const clone = $(this).prev().clone();
                                clone.find("input[type=text], textarea").val("");
                                clone.find("input[type=checkbox]").prop("checked", false);
                                const numResponses = clone.find(".response").length;
                                for (let i = numResponses; i > 1; i--) {
                                    clone.find(".response:last").remove();
                                }
                                $(this).before(clone);
                                updateQuestionIndices();
                                updateEventListeners();
                            });
                            $("button.remove-question").off("click").on("click", function (e) {
                                e.preventDefault();
                                const containers = modalBody.find(".question");
                                const numContainers = containers.length;
                                if (numContainers > 1) {
                                    $(this).parents(".question:first").remove();
                                }
                                updateQuestionIndices();
                            });
                            $("button.remove-response").off("click").on("click", function (e) {
                                e.preventDefault();
                                const parentQuestion = $(this).parents(".question:first")
                                const otherResponses = parentQuestion.find(".response");
                                if (otherResponses.length > 1) {
                                    const response = $(this).parents(".response:first");
                                    response.remove();
                                }
                                updateQuestionIndices();
                            });
                        };
                        updateEventListeners();
                    });
                });
            });
        }).trigger("show.bs.tab");

        $("#element-registry-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/elements";
            $.get(url, function (data) {
                $("#element-registry-tab-content").html(data);
                RegisteredElementsView.initialize();
            });
        });

        $("#imports-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/imports";
            $.get(url, function (data) {
                $("#imports-tab-content").html(data);
                ImportsView.initialize();
            });
        });

        $("#invitees-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/invitees";
            $.get(url, function (data) {
                $("#invitees-tab-content").html(data);
                InviteesView.initialize();
            });
        });

        $("#metadata-profiles-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/metadata-profiles";
            $.get(url, function (data) {
                $("#metadata-profiles-tab-content").html(data);
                MetadataProfilesView.initialize();
            });
        });

        $("#submission-profiles-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/submission-profiles";
            $.get(url, function (data) {
                $("#submission-profiles-tab-content").html(data);
                SubmissionProfilesView.initialize();
            });
        });

        $("#vocabularies-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/vocabularies";
            $.get(url, function (data) {
                $("#vocabularies-tab-content").html(data);
                VocabulariesView.initialize();
            });
        });

        $("#prebuilt-searches-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/prebuilt-searches";
            $.get(url, function (data) {
                $("#prebuilt-searches-tab-content").html(data);
                PrebuiltSearchesView.initialize();
            });
        });

        $("#index-pages-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/index-pages";
            $.get(url, function (data) {
                $("#index-pages-tab-content").html(data);
                IndexPagesView.initialize();
            });
        });

        $("#review-submissions-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/review-submissions";
            $.get(url, function (data) {
                $("#review-submissions-tab-content").html(data);
            });
        });

        $("#submissions-in-progress-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/submissions-in-progress";
            $.get(url, function (data) {
                $("#submissions-in-progress-tab-content").html(data);
            });
        });

        $("#theme-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/theme";
            $.get(url, function (data) {
                $("#theme-tab-content").html(data);
                $('button.edit-theme').on("click", function () {
                    const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-theme";
                    $.get(url, function (data) {
                        $("#edit-theme-modal .modal-body").html(data);
                    });
                });
            });
        });

        $("#units-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/units";
            $.get(url, function (data) {
                $("#units-tab-content").html(data);
                UnitsView.initialize();
            });
        });

        $("#usage-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/usage";
            $.get(url, function (data) {
                $("#usage-tab-content").html(data);
            });
        });

        $("#user-groups-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/user-groups";
            $.get(url, function (data) {
                $("#user-groups-tab-content").html(data);
                UserGroupsView.initialize();
            });
        });

        $("#users-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/users";
            $.get(url, function (data) {
                $("#users-tab-content").html(data);
            });
        });

        $("#statistics-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/statistics";
            $.get(url, function (data) {
                const statsTabContent = $("#statistics-tab-content");
                statsTabContent.html(data);

                const refreshStatisticsByMonth = function () {
                    const innerTabContent = $("#statistics-by-month-tab-content");
                    innerTabContent.html(IDEALS.UIUtils.Spinner());
                    const url = ROOT_URL + "/institutions/" + institutionKey + "/statistics-by-range?" +
                        statsTabContent.find("form").serialize();
                    $.ajax({
                        method: "GET",
                        url: url,
                        success: function (data) {
                            $("#error-flash").hide();
                            innerTabContent.html(data);
                        },
                        error: function (data, status, xhr) {
                            $("#error-flash").text(data.responseText).show();
                        }
                    });
                };
                const refreshDownloadsByItem = function () {
                    const innerTabContent = $("#downloads-by-item-tab-content");
                    innerTabContent.html(IDEALS.UIUtils.Spinner());
                    const url = ROOT_URL + "/institutions/" + institutionKey + "/item-download-counts?" +
                        statsTabContent.find("form").serialize();
                    $.get(url, function (data) {
                        innerTabContent.html(data);
                    });
                };

                $("#statistics-by-month-tab").on("show.bs.tab", function () {
                    refreshStatisticsByMonth()
                }).trigger("show.bs.tab");
                $("#downloads-by-item-tab").on("show.bs.tab", function () {
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

        $("#access-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/access";
            $.get(url, function (data) {
                $("#access-tab-content").html(data);

                $('.edit-administering-groups').on("click", function () {
                    const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-administering-groups";
                    $.get(url, function (data) {
                        $("#edit-administering-groups-modal .modal-body").html(data);
                        new IDEALS.UIUtils.MultiElementList();
                    });
                });
                $('.edit-administering-users').on("click", function () {
                    const url = ROOT_URL + "/institutions/" + institutionKey + "/edit-administering-users";
                    $.get(url, function (data) {
                        $("#edit-administering-users-modal .modal-body").html(data);
                        new IDEALS.UIUtils.UserAutocompleter(
                            $("input[name=primary_administrator], input[name='administering_users[]']"), true);
                        new IDEALS.UIUtils.MultiElementList();
                    });
                });
            });
        });

        $("#element-mappings-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/element-mappings";
            $.get(url, function (data) {
                $("#element-mappings-tab-content").html(data);
                $("button.edit-element-mappings").on("click", function () {
                    $.get(url + "/edit", function (data) {
                        const modalBody = $("#edit-element-mappings-modal .modal-body");
                        modalBody.html(data);
                    });
                });
            });
        });

        $("#element-namespaces-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/element-namespaces";
            $.get(url, function (data) {
                $("#element-namespaces-tab-content").html(data);
                ElementNamespacesView.initialize();
            });
        });

        $("#withdrawn-items-tab").on("show.bs.tab", function () {
            const url = ROOT_URL + "/institutions/" + institutionKey + "/withdrawn-items";
            $.get(url, function (data) {
                $("#withdrawn-items-tab-content").html(data);

                const attachResultsEventListeners = function() {
                    $(".page-link").on("click", function(e) {
                        e.preventDefault();
                        refreshResults($(this).attr("href"));
                    });
                };
                attachResultsEventListeners();

                const refreshResults = function(url) {
                    const container = $("#withdrawn-items-tab-content");
                    container.html(IDEALS.UIUtils.Spinner());
                    if (!url) {
                        url = ROOT_URL + "/institutions/" + institutionKey + "/withdrawn-items";
                    }
                    $.ajax({
                        method:  "GET",
                        url:     url,
                        success: function(data) {
                            container.html(data);
                            attachResultsEventListeners();
                        }
                    });
                };
            });
        });
    }

};

$(document).ready(function() {
    if ($("body#institutions").length) {
        InstitutionsView.initialize();
    } else if ($("body#show_institution").length) {
        InstitutionView.initialize();
    }
});
