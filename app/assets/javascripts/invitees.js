const InviteesView = {

    AddInviteeClickHandler: function() {
        const ROOT_URL      = $("input[name=root_url]").val();
        const institutionID = $("input[name=institution_id]").val();
        const url           = ROOT_URL + "/invitees/new?" +
            "invitee%5Binstitution_id%5D=" + institutionID;
        $.get(url, function (data) {
            $("#add-invitee-modal .modal-body").html(data);
        });
    },

    /**
     * Handles list-invitees view.
     */
    initialize: function() {
        $("button.add-invitee").on("click", this.AddInviteeClickHandler);

        const InviteeFilterForm = function() {
            const ROOT_URL    = $("input[name=root_url]").val();
            const form        = $("#invitees-form");
            const filterField = $("[name=q]");
            const container   = $("#invitees-xhr-content");

            const attachResultsEventListeners = function() {
                $(".page-link").on("click", function(e) {
                    e.preventDefault();
                    refreshResults($(this).attr("href"));
                });
                $("button.reject").on("click", function() {
                    const invitee_id = $(this).data("invitee-id");
                    const url        = ROOT_URL + "/invitees/" + invitee_id + "/edit";
                    $.get(url, function(data) {
                        $("#reject-modal .modal-body").html(data);
                    });
                });
            };

            const refreshResults = function(url) {
                container.html(IDEALS.UIUtils.Spinner());
                if (!url) {
                    url = form.attr("action");
                }
                $.ajax({
                    method:  "GET",
                    url:     url,
                    data:    form.serialize(),
                    dataType: "script",
                    success: function(data) {
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
            $("[name=institution_id], [name=approval_state]").on("change", function() {
                refreshResults();
            }).trigger("change");
        };
        new InviteeFilterForm();
    }

};


$(document).ready(function() {
    if ($("body#list_invitees").length) {
        InviteesView.initialize();
    }
});
