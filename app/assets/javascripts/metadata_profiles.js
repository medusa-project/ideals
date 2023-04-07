/**
 * Handles list-metadata-profiles view (/metadata-profiles).
 *
 * @constructor
 */
const MetadataProfilesView = function() {
    const ROOT_URL      = $("input[name=root_url]").val();
    const institutionID = $("input[name=institution_id]").val();

    $('button.add-metadata-profile').on("click", function() {
        const url = ROOT_URL + "/metadata-profiles/new?" +
            "metadata_profile%5Binstitution_id%5D=" + institutionID;
        $.get(url, function(data) {
            $("#add-metadata-profile-modal .modal-body").html(data);
            new IDEALS.CheckAllButton($('.check-all'),
                $("input[name='elements[]']"));
        });
    });
    $('button.edit-metadata-profile').on("click", function() {
        const profile_id = $(this).data("metadata-profile-id");
        const url = ROOT_URL + "/metadata-profiles/" + profile_id + "/edit";
        $.get(url, function(data) {
            $("#edit-metadata-profile-modal .modal-body").html(data);
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

    $('button.edit-metadata-profile').on("click", function() {
        const profile_id = $(this).data("metadata-profile-id");
        const url = ROOT_URL + "/metadata-profiles/" + profile_id + "/edit";
        $.get(url, function(data) {
            $("#edit-metadata-profile-modal .modal-body").html(data);
        });
    });
    $("button.edit-element").on("click", function() {
        const profile_id = $(this).data("metadata-profile-id");
        const element_id = $(this).data("element-id");
        const url = ROOT_URL + "/metadata-profiles/" + profile_id +
            "/elements/" + element_id + "/edit";
        $.get(url, function(data) {
            $("#edit-element-modal .modal-body").html(data);
            $("#indexed-warning").hide();
            $("input[name='metadata_profile_element[indexed]']").on("change", function() {
                $("#indexed-warning").show();
            });
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
