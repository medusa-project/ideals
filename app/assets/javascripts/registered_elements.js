const RegisteredElements = {

    AddRegisteredElementClickHandler: function() {
        const ROOT_URL      = $("input[name=root_url]").val();
        const institutionID = $("input[name=institution_id]").val();
        const url           = ROOT_URL + "/elements/new?" +
            "registered_element%5Binstitution_id%5D=" + institutionID;
        $.get(url, function (data) {
            $("#add-element-modal .modal-body").html(data);
            new IDEALS.UIUtils.CheckAllButton($('.check-all'),
                $("input[name='elements[]']"));
        });
    },

    EditRegisteredElementClickHandler: function() {
        const ROOT_URL  = $("input[name=root_url]").val();
        const elementID = $(this).data('element-id');
        const url       = ROOT_URL + "/elements/" + elementID + "/edit";
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
    },

    /**
     * @constructor
     */
    RegisteredElementsView: function() {
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
        $("button.add-element").on("click",
            RegisteredElements.AddRegisteredElementClickHandler);
        $('button.edit-element').on('click',
            RegisteredElements.EditRegisteredElementClickHandler);
    }

}

$(document).ready(function() {
    if ($("body#registered_elements").length) {
        new RegisteredElements.RegisteredElementsView();
    }
});
