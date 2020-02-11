/**
 * Handles list-metadata-profiles view (/metadata-profiles).
 *
 * @constructor
 */
const MetadataProfilesView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    $('button.edit-profile').on("click", function() {
        const profile_id = $(this).data("profile-id");
        const url = ROOT_URL + "/metadata-profiles/" + profile_id + "/edit";
        $.get(url, function(data) {
            $("#edit-profile-modal .modal-body").html(data);
        });
    });
};

/**
 * Handles show-metadata-profile view (/metadata-profiles/:id).
 *
 * @constructor
 */
const MetadataProfileView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    $("button.edit-element").on("click", function() {
        const profile_id = $(this).data("profile-id");
        const element_id = $(this).data("element-id");
        const url = ROOT_URL + "/metadata-profiles/" + profile_id +
            "/elements/" + element_id + "/edit";
        $.get(url, function(data) {
            $("#edit-element-modal .modal-body").html(data);
        });
    });
};

$(document).ready(function() {
    if ($('body#metadata_profiles').length) {
        new MetadataProfilesView();
    } else if ($("body#show_metadata_profile").length) {
        new MetadataProfileView();
    }
});
