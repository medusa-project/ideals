/**
 * @constructor
 */
const GlobalLandingView = function() {
    const r                 = $(".institution-point").attr("r");
    const institution_links = $(".institution");
    institution_links.on("mouseenter", function() {
        const key          = $(this).data("key");
        const point        = $("#" + key + "-point");
        const last_sibling = point.siblings(":last");
        // Move the point past its last sibling to prevent it from being
        // obscured by overlapping points.
        point.insertAfter(last_sibling);
        point.addClass("selected");
        point.animate({ r: r * 1.5 }, 150);
    }).on("mouseleave", function() {
        const key   = $(this).data("key");
        const point = $("#" + key + "-point");
        point.removeClass("selected");
        point.animate({ r: r }, 150);
    });
};

$(document).ready(function() {
    if ($("body#global-landing").length) {
        new GlobalLandingView();
    }
});
