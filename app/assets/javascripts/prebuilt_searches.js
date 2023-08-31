/**
 * Handles prebuilt searches view (/prebuilt-searches).
 */
const PrebuiltSearchesView = {

    AddPrebuiltSearchClickHandler: function () {
        const ROOT_URL = $('input[name="root_url"]').val();
        const institutionID = $("[name=institution_id]").val();
        const url = ROOT_URL + "/prebuilt-searches/new?" +
            "prebuilt_search%5Binstitution_id%5D=" + institutionID;
        $.get(url, function (data) {
            $("#add-prebuilt-search-modal .modal-body").html(data);
        });
    },

    EditPrebuiltSearchClickHandler: function () {
        const ROOT_URL = $('input[name="root_url"]').val();
        const url = ROOT_URL + "/prebuilt-searches/" +
            $(this).data("id") + "/edit";
        $.get(url, function (data) {
            $("#edit-prebuilt-search-modal .modal-body").html(data);
            new IDEALS.UIUtils.MultiElementList();
        });
    },

    initialize: function() {
        $("button.add-prebuilt-search").on("click",
            PrebuiltSearchesView.AddPrebuiltSearchClickHandler);
    }

};

/**
 * Handles edit-prebuilt-search view (/prebuilt-searches/:id).
 */
const PrebuiltSearchView = {

    initialize: function() {
        const copyButton = $(".copy-search-link");
        new IDEALS.UIUtils.CopyButton(copyButton, $(".search-link-html"));
        $('button.edit-prebuilt-search').on("click",
            PrebuiltSearchesView.EditPrebuiltSearchClickHandler);
    }

};

$(document).ready(function() {
    if ($("body#prebuilt_searches").length) {
        PrebuiltSearchesView.initialize();
    } else if ($("body#show_prebuilt_search").length) {
        PrebuiltSearchView.initialize();
    }
});
