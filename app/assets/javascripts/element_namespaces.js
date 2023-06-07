const ElementNamespaces = {

    AddElementNamespaceClickHandler: function() {
        const ROOT_URL      = $("input[name=root_url]").val();
        const institutionID = $("input[name=institution_id]").val();
        const url           = ROOT_URL + "/element-namespaces/new?" +
            "element_namespace%5Binstitution_id%5D=" + institutionID;
        $.get(url, function(data) {
            $("#add-element-namespace-modal .modal-body").html(data);
        });
    },

    EditElementNamespaceClickHandler: function() {
        const ROOT_URL = $("input[name=root_url]").val();
        const nsID     = $(this).data("element-namespace-id");
        const url      = ROOT_URL + "/element-namespaces/" + nsID + "/edit";
        $.get(url, function(data) {
            $("#edit-element-namespace-modal .modal-body").html(data);
        });
    },

    /**
     * Handles list-element-namespaces view (/element-namespaces).
     */
    ElementNamespacesView: function() {
        $("button.add-element-namespace").on("click",
            ElementNamespaces.AddElementNamespaceClickHandler);
        $("button.edit-element-namespace").on("click",
            ElementNamespaces.EditElementNamespaceClickHandler);
    }

};

$(document).ready(function() {
    if ($("body#element_namespaces").length) {
        new ElementNamespaces.ElementNamespacesView();
    }
});
