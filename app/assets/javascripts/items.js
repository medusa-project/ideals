/**
 * @constructor
 */
const ItemsView = function() {
    new IDEALS.FacetSet().init();
};

$(document).ready(function() {
    if ($("body#list_items").length) {
        new ItemsView();
    }
});
