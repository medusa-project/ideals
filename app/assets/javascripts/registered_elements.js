/**
 * @constructor
 */
const RegisteredElementsView = function() {

    const ROOT_URL = $('input[name="root_url"]').val();

    // Implement a simple client-side search.
    $("[name=q]").on("keyup", function(e) {
        if (e.which === 13) { // disable submission on enter
            e.preventDefault();
            return false;
        }
        const q      = $(this).val().toLowerCase();
        const names  = $(".element-name");
        const labels = $(".element-label");
        for (let i = 0; i < names.length; i++) {
            const nameNode  = $(names[i]);
            const labelNode = $(labels[i]);
            const card      = nameNode.parents(".card");
            if (nameNode.text().toLowerCase().includes(q) ||
                    labelNode.text().toLowerCase().includes(q)) {
                card.show();
            } else {
                card.hide();
            }
        }
    });

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
