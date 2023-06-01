const SubmissionProfiles = {

    AddSubmissionProfileClickHandler: function() {
        const ROOT_URL      = $("input[name=root_url]").val();
        const institutionID = $("input[name=institution_id]").val();
        const url           = ROOT_URL + "/submission-profiles/new?" +
            "submission_profile%5Binstitution_id%5D=" + institutionID;
        $.get(url, function(data) {
            $("#add-submission-profile-modal .modal-body").html(data);
            new IDEALS.UIUtils.CheckAllButton($('.check-all'),
                $("input[name='elements[]'][data-required=false]"));
        });
    },

    EditSubmissionProfileClickHandler: function() {
        const ROOT_URL   = $("input[name=root_url]").val();
        const profile_id = $(this).data("submission-profile-id");
        const url        = ROOT_URL + "/submission-profiles/" + profile_id +
            "/edit";
        $.get(url, function(data) {
            $("#edit-submission-profile-modal .modal-body").html(data);
        });
    },

    /**
     * Handles list-metadata-profiles view (/metadata-profiles).
     */
    SubmissionProfilesView: function() {
        $('button.add-submission-profile').on("click",
            SubmissionProfiles.AddSubmissionProfileClickHandler);
        $('button.edit-submission-profile').on("click",
            SubmissionProfiles.EditSubmissionProfileClickHandler);
    },

    /**
     * Handles show-submission-profile view (/submission-profiles/:id).
     */
    SubmissionProfileView: function() {
        const ROOT_URL = $('input[name="root_url"]').val();

        $('button.edit-submission-profile').on("click",
            SubmissionProfiles.EditSubmissionProfileClickHandler);
        $("button.add-element").on("click", function() {
            const profile_id = $(this).data("submission-profile-id");
            const url        = ROOT_URL + "/submission-profiles/" + profile_id +
                "/elements/new";
            $.get(url, function(data) {
                const modalBody = $("#add-element-modal .modal-body");
                modalBody.html(data);
            });
        });
        $("button.edit-element").on("click", function() {
            const profile_id = $(this).data("submission-profile-id");
            const element_id = $(this).data("element-id");
            const url        = ROOT_URL + "/submission-profiles/" + profile_id +
                "/elements/" + element_id + "/edit";
            $.get(url, function(data) {
                const modalBody = $("#edit-element-modal .modal-body");
                modalBody.html(data);
            });
        });
    }

};

$(document).ready(function() {
    if ($("body#submission_profiles").length) {
        new SubmissionProfiles.SubmissionProfilesView();
    } else if ($("body#show_submission_profile").length) {
        new SubmissionProfiles.SubmissionProfileView();
    }
});
