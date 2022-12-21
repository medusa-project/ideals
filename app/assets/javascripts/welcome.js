/**
 * @constructor
 */
const GlobalLandingView = function() {
    const r                 = $(".institution-point").attr("r");
    const institution_links = $(".institution");
    institution_links.on("mouseenter", function() {
        const key   = $(this).data("key");
        const point = $("#" + key + "-point");
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
