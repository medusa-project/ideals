/**
 * Handles list-units view.
 *
 * @constructor
 */
const UnitsView = function() {
    new IDEALS.UserAutocompleter(
        $("input[name=primary_administrator], input[name='administering_users[]']"));
    new IDEALS.MultiUserList();
};

/**
 * Handles show-unit view.
 *
 * @constructor
 */
const UnitView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    $('button.edit-unit').on("click", function() {
        const id = $(this).data("unit-id");
        const url = ROOT_URL + "/units/" + id + "/edit";
        $.get(url, function(data) {
            $('#edit-unit-modal .modal-body').html(data);
            new IDEALS.UserAutocompleter(
                $("input[name=primary_administrator], input[name='administering_users[]']"));
            new IDEALS.MultiUserList();
        });
    });
};

$(document).ready(function() {
    if ($('body#units_index').length) {
        new UnitsView();
    } else if ($("body#show_unit").length) {
        new UnitView();
    }
});
