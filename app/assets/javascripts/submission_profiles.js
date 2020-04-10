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
            const modalBody = $("#edit-element-modal .modal-body");
            modalBody.html(data);
            // Conditionally enable/disable a couple of other inputs when the
            // vocabulary select menu is changed.
            modalBody.find("#submission_profile_element_vocabulary_key").on("change", function() {
                const disabled = ($(this).val().length > 0);
                modalBody.find("#submission_profile_element_input_type").prop("disabled", disabled);
                modalBody.find("#submission_profile_element_placeholder_text").prop("disabled", disabled);
            }).trigger("change");
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
