/**
 * Handles list-metadata-profiles view (/metadata-profiles).
 *
 * @constructor
 */
const SubmissionProfilesView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    $('button.edit-profile').on("click", function() {
        const profile_id = $(this).data("profile-id");
        const url = ROOT_URL + "/submission-profiles/" + profile_id + "/edit";
        $.get(url, function(data) {
            $("#edit-profile-modal .modal-body").html(data);
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

    $('button.edit-profile').on("click", function() {
        const profile_id = $(this).data("profile-id");
        const url = ROOT_URL + "/submission-profiles/" + profile_id + "/edit";
        $.get(url, function(data) {
            $("#edit-profile-modal .modal-body").html(data);
        });
    });
    $("button.edit-element").on("click", function() {
        const profile_id = $(this).data("profile-id");
        const element_id = $(this).data("element-id");
        const url = ROOT_URL + "/submission-profiles/" + profile_id +
            "/elements/" + element_id + "/edit";
        $.get(url, function(data) {
            $("#edit-element-modal .modal-body").html(data);
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
