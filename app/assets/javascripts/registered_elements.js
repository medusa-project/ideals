/**
 * @constructor
 */
const RegisteredElementsView = function() {

    const ROOT_URL = $('input[name="root_url"]').val();

    $('button.edit-element').on('click', function() {
        const element_name = $(this).data('element-name');
        const url = ROOT_URL + '/elements/' + element_name + '/edit';
        $.get(url, function(data) {
            const modalBody = $("#edit-element-modal .modal-body");
            modalBody.html(data);
            // Conditionally enable/disable a couple of other inputs when the
            // vocabulary select menu is changed.
            modalBody.find("#registered_element_vocabulary_key").on("change", function() {
                const disabled = ($(this).val().length > 0);
                modalBody.find("#registered_element_input_type").prop("disabled", disabled);
            }).trigger("change");
        });
    });

};

var ready = function() {
    if ($('body#registered_elements').length) {
        new RegisteredElementsView();
    }
};

$(document).ready(ready);
