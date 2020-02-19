/**
 * @constructor
 */
const UserList = function() {
    $("button.add").on("click", function(e) {
        const clone = $(this).prev().clone();
        clone.find("input").val("");
        $(this).before(clone);
        addRemoveEventListeners();
        new IDEALS.UserAutocompleter(clone.find("input"));
        e.preventDefault();
    });
    addRemoveEventListeners();

    function addRemoveEventListeners() {
        $("button.remove").off("click").on("click", function () {
            if ($(this).parents("form").find(".user").length > 1) {
                $(this).parents(".user").remove();
            }
        });
    }
};

/**
 * Handles list-units view.
 *
 * @constructor
 */
const UnitsView = function() {
    new IDEALS.UserAutocompleter($("input[name=primary_administrator]"));
    new IDEALS.UserAutocompleter($("input[name='administering_users[]']"));
    new UserList();
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
            new IDEALS.UserAutocompleter($("input[name=primary_administrator]"));
            new IDEALS.UserAutocompleter($("input[name='administering_users[]']"));
            new UserList();
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
