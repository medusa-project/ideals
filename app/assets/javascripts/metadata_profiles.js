/**
 * @constructor
 */
const MetadataProfilesView = function() {

    const ROOT_URL = $('input[name="root_url"]').val();

    $('button.edit-profile').on('click', function() {
        var profile_id = $(this).data('profile-id');
        var url = ROOT_URL + '/metadata-profiles/' + profile_id + '/edit';
        $.get(url, function(data) {
            $('#edit-profile-modal .modal-body').html(data);
        });
    });

};

$(document).ready(function() {
    if ($('body#metadata_profiles').length) {
        new MetadataProfilesView();
    }
});
