/**
 * Handles list-metadata-profiles view (/metadata-profiles).
 *
 * @constructor
 */
const SubmissionProfilesView = function() {
    const ROOT_URL      = $("input[name=root_url]").val();
    const institutionID = $("input[name=institution_id]").val();

    $('button.add-submission-profile').on("click", function() {
        const url = ROOT_URL + "/submission-profiles/new?" +
            "submission_profile%5Binstitution_id%5D=" + institutionID;
        $.get(url, function(data) {
            $("#add-submission-profile-modal .modal-body").html(data);
            new IDEALS.CheckAllButton($('.check-all'),
                $("input[name='elements[]'][data-required=false]"));
        });
    });
    $('button.edit-submission-profile').on("click", function() {
        const profile_id = $(this).data("submission-profile-id");
        const url = ROOT_URL + "/submission-profiles/" + profile_id + "/edit";
        $.get(url, function(data) {
            $("#edit-submission-profile-modal .modal-body").html(data);
        });
    });
};

/**
 * Handles show-submission-profile view (/submission-profiles/:id).
 *
 * @constructor
 */
const SubmissionProfileView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    $('button.edit-submission-profile').on("click", function() {
        const profile_id = $(this).data("submission-profile-id");
        const url = ROOT_URL + "/submission-profiles/" + profile_id + "/edit";
        $.get(url, function(data) {
            $("#edit-submission-profile-modal .modal-body").html(data);
        });
    });
    $("button.edit-element").on("click", function() {
        const profile_id = $(this).data("submission-profile-id");
        const element_id = $(this).data("element-id");
        const url = ROOT_URL + "/submission-profiles/" + profile_id +
            "/elements/" + element_id + "/edit";
        $.get(url, function(data) {
            const modalBody = $("#edit-element-modal .modal-body");
            modalBody.html(data);
        });
    });
};

$(document).ready(function() {
    if ($('body#submission_profiles').length) {
        new SubmissionProfilesView();
    } else if ($("body#show_submission_profile").length) {
        new SubmissionProfileView();
    }
});
