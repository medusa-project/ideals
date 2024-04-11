/**
 * Handles search view (/search).
 */
const SearchView = {

    initialize: function () {
        new IDEALS.UIUtils.FacetSet().init();

        const params              = new URLSearchParams(window.location.search);
        const allItemsTab         = $("#all-items-tab");
        const simpleSearchTab     = $("#simple-search-tab");
        const simpleSearchContent = $("#simple-search");
        const advSearchTab        = $("#advanced-search-tab");
        const advSearchContent    = $("#advanced-search");
        // Since all of tabs are in the same <form>, we will need to clear all
        // of the fields in the other tab(s) when the form is submitted.
        // Keeping track of the current tab enables us to infer the non-current
        // tabs.
        let currentTab = allItemsTab;
        allItemsTab.on("click", function () {
            window.location = "/search";
        });
        simpleSearchTab.on("show.bs.tab", function () {
            currentTab = simpleSearchTab;
        });
        advSearchTab.on("show.bs.tab", function () {
            currentTab = advSearchTab;
        });

        // Select a search-type tab based on the URL query arguments.
        if (params.get("tab") === "advanced-search") {
            advSearchTab.tab("show");
        } else if (params.get("q")) {
            simpleSearchTab.tab("show");
        } else {
            let found = false;
            advSearchContent.find("input, select").each(function () {
                found = true;
                if (params.get($(this).attr("name"))) {
                    advSearchTab.tab('show');
                }
            });
            if (!found && !allItemsTab.hasClass("active")) {
                allItemsTab.tab('show');
            }
        }

        // Fill in advanced search fields from the URL query, which the browser
        // won't do automatically.
        advSearchContent.find("input[type=text], input[type=number], select").each(function () {
            $(this).val(params.get($(this).attr("name")));
        });

        advSearchContent.find(".date-picker").each(function () {
            IDEALS.UIUtils.DatePicker($(this).find("select:last"),
                $(this).find("select:first"),
                $(this).find("select:nth(1)"));
        });

        $("[name=item_type]").on("change", function() {
            $(this).parents("form:first").submit();
        });

        // When the Simple Search or Advanced Search submit button is clicked,
        // clear all form fields in the other tab pane, so they don't get sent
        // along as well.
        $("input[type=submit]").on("click", function () {
            let otherTabContent;
            switch (currentTab.attr("id")) {
                case "simple-search-tab":
                    otherTabContent = advSearchContent;
                    break;
                case "advanced-search-tab":
                    otherTabContent = simpleSearchContent;
                    break;
            }
            otherTabContent.find("input, select, textarea").remove();
        });

        // When a date search type tab is changed, clear the input from
        // the hidden tab.
        advSearchContent.find('.date-search-type > li > a[data-bs-toggle="pill"]').on('hidden.bs.tab', function (e) {
            const hiddenPane = $($(e.target).attr("href"));
            hiddenPane.find("select > option:first-child").prop("selected", "selected");
        });
    }
};


$(document).ready(function() {
    if ($("body#search").length) {
        SearchView.initialize();
    }
});
