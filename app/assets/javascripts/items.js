/**
 * @constructor
 */
const ItemsView = function() {
    new IDEALS.FacetSet().init();
};

$(document).ready(function() {
    if ($('body#items_index').length) {
        new ItemsView();
    }
});
