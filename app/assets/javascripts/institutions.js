/**
 * Handles show-institution view (/institutions/:key).
 *
 * @constructor
 */
const InstitutionView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    $('button.edit-institution').on("click", function() {
        const key = $(this).data("institution-key");
        const url = ROOT_URL + "/institutions/" + key + "/edit";
        $.get(url, function(data) {
            $("#edit-institution-modal .modal-body").html(data);
        });
    });
};

$(document).ready(function() {
    if ($('body#show_institution').length) {
        new InstitutionView();
    }
});
