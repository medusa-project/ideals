/**
 * Handles list-units view.
 *
 * @constructor
 */
const UnitsView = function() {
    new IDEALS.ExpandableUnitList();
    new IDEALS.UserAutocompleter(
        $("input[name=primary_administrator], input[name='administering_users[]']"));
    new IDEALS.MultiElementList();
};

/**
 * Handles show-unit view.
 *
 * @constructor
 */
const UnitView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    $('.edit-unit-access').on("click", function() {
        const id = $(this).data("unit-id");
        const url = ROOT_URL + "/units/" + id + "/edit-access";
        $.get(url, function(data) {
            $("#edit-unit-access-modal .modal-body").html(data);
            new IDEALS.UserAutocompleter(
                $("input[name=primary_administrator], input[name='administering_users[]']"));
            new IDEALS.MultiElementList();
        });
    });
    $('.edit-unit-membership').on("click", function() {
        const id = $(this).data("unit-id");
        const url = ROOT_URL + "/units/" + id + "/edit-membership";
        $.get(url, function(data) {
            $("#edit-unit-membership-modal .modal-body").html(data);
        });
    });
    $('.edit-unit-properties').on("click", function() {
        const id = $(this).data("unit-id");
        const url = ROOT_URL + "/units/" + id + "/edit-properties";
        $.get(url, function(data) {
            $("#edit-unit-properties-modal .modal-body").html(data);
        });
    });
};

$(document).ready(function() {
    if ($("body#list_units").length) {
        new UnitsView();
    } else if ($("body#show_unit").length) {
        new UnitView();
    }
});
