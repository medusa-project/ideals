/**
 * Handles prebuilt searches view (/prebuilt-searches).
 *
 * @constructor
 */
const PrebuiltSearchesView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    $('button.add-prebuilt-search').on("click", function() {
        const url = ROOT_URL + "/prebuilt-searches/new";
        $.get(url, function(data) {
            $("#add-prebuilt-search-modal .modal-body").html(data);
        });
    });

};

/**
 * Handles edit-prebuilt-search view (/prebuilt-searches/:id).
 *
 * @constructor
 */
const PrebuiltSearchView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    const copyButton = $(".copy-search-link");
    new IDEALS.CopyButton(copyButton, $(".search-link-html"));

    $('button.edit-prebuilt-search').on("click", function() {
        const url = ROOT_URL + "/prebuilt-searches/" + $(this).data("id") + "/edit";
        $.get(url, function(data) {
            $("#edit-prebuilt-search-modal .modal-body").html(data);
            new IDEALS.MultiElementList();
        });
    });

};

$(document).ready(function() {
    if ($("body#prebuilt_searches").length) {
        new PrebuiltSearchesView();
    } else if ($("body#show_prebuilt_search").length) {
        new PrebuiltSearchView();
    }
});
