const IndexPages = {

    AddIndexPageClickHandler: function() {
        const ROOT_URL      = $('input[name="root_url"]').val();
        const institutionID = $("input[name=institution_id]").val();
        const url           = ROOT_URL + "/index-pages/new?" +
            "index_page%5Binstitution_id%5D=" + institutionID;
        $.get(url, function(data) {
            $("#add-index-page-modal .modal-body").html(data);
        });
    },

    /**
     * Handles index pages view (/index-pages).
     */
    IndexPagesView: function() {
        $("button.add-index-page").on("click",
            IndexPages.AddIndexPageClickHandler);
    },

    /**
     * Handles show-index-page view (/index-pages/:id).
     */
    IndexPageView: function() {
        const ROOT_URL = $('input[name="root_url"]').val();
        $("button.edit-index-page").on("click", function() {
            const url = ROOT_URL + "/index-pages/" + $(this).data("id") + "/edit";
            $.get(url, function(data) {
                $("#edit-index-page-modal .modal-body").html(data);
            });
        });
    }

};

$(document).ready(function() {
    if ($("body#index_pages").length) {
        new IndexPages.IndexPagesView();
    } else if ($("body#show_index_page").length) {
        new IndexPages.IndexPageView();
    }
});
