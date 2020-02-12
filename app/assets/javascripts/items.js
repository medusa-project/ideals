/**
 * @constructor
 */
const ItemsView = function() {
    new IDEALS.FacetSet().init();

    // Copy the URL "q" argument into the filter field, as the browser won't do
    // this automatically.
    const queryArgs = new URLSearchParams(location.search);
    if (queryArgs.has("q")) {
        $("input[name=q]").val(queryArgs.get("q"));
    }
};

$(document).ready(function() {
    if ($('body#items_index').length) {
        new ItemsView();
    }
});
