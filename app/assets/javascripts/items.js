/**
 * Handles list-items view (/items).
 *
 * @constructor
 */
const ItemsView = function() {
    new IDEALS.FacetSet().init();

    const params              = new URLSearchParams(window.location.search);
    const allItemsTab         = $("#all-items-tab");
    const simpleSearchTab     = $("#simple-search-tab");
    const simpleSearchContent = $("#simple-search");
    const advSearchTab        = $("#advanced-search-tab");
    const advSearchContent    = $("#advanced-search");
    // Since all of tabs are in the same <form>, we will need to clear all of
    // the fields in the other tab(s) when the form is submitted. Keeping track
    // of the current tab enables us to infer the non-current tabs.
    var currentTab;
    allItemsTab.on("shown.bs.tab", function() { currentTab = allItemsTab; });
    simpleSearchTab.on("shown.bs.tab", function() { currentTab = simpleSearchTab; });
    advSearchTab.on("shown.bs.tab", function() { currentTab = advSearchTab; });

    // Select a search-type tab based on the URL query arguments.
    if (params.get("tab") === "advanced-search") {
        advSearchTab.tab("show");
    } else if (params.get("q")) {
        simpleSearchTab.tab("show");
    } else {
        let found = false;
        advSearchContent.find("input, select").each(function() {
            found = true;
            if (params.get($(this).attr("name"))) {
                advSearchTab.tab('show');
            }
        });
        if (!found) {
            allItemsTab.tab('show');
        }
    }

    // Fill in advanced search fields from the URL query, which the browser
    // won't do automatically.
    advSearchContent.find("input[type=text], input[type=number], select").each(function() {
        $(this).val(params.get($(this).attr("name")));
    });

    // When the All Items tab is selected, remove all other search input.
    allItemsTab.on("show.bs.tab", function() {
        window.location = "/items";
    });

    // When the Simple Search or Advanced Search submit button is clicked,
    // clear all form fields in the other tab pane, so they don't get sent
    // along as well.
    $("input[type=submit]").on("click", function() {
        let otherTabContent;
        switch (currentTab.attr("id")) {
            case "simple-search-tab":
                otherTabContent = advSearchContent;
                break;
            case "advanced-search-tab":
                otherTabContent = simpleSearchContent;
                break;
        }
        otherTabContent.find("input[type=text], input[type=search], textarea").val("");
        otherTabContent.find("option:first-child").prop("selected", "selected");
    });

    // When a date search type tab is changed, clear the input from
    // the hidden tab.
    advSearchContent.find('.date-search-type > li > a[data-bs-toggle="pill"]').on('hidden.bs.tab', function(e) {
        const hiddenPane = $($(e.target).attr("href"));
        hiddenPane.find("select > option:first-child").prop("selected", "selected");
    });
};

/**
 * Controls the file navigator in item view.
 *
 * @constructor
 */
const FileNavigator = function() {
    const HEADER_HEIGHT = 50;
    const FOOTER_HEIGHT = 50;
    const ROOT_URL      = $('input[name=root_url]').val();
    const ITEM_ID       = $("input[name=item_id]").val();
    const navigator     = $("#file-navigator");

    // Set the initial height of the viewer container.
    const navigatorHeight = window.innerHeight - 100;
    navigator.css("height", navigatorHeight + "px");

    // Load the navigator HTML.
    $.ajax({
        method: "GET",
        url:    ROOT_URL + "/items/" + ITEM_ID + "/file-navigator",
        success: function(data) {
            navigator.css("display", "grid");
            navigator.css("grid-template-columns", "30% 70%");
            navigator.html(data);
            navigator.trigger("IDEALS.FileNavigator.thumbsLoaded");
        },
        error: function(data, status, xhr) {
        }
    });

    navigator.on("IDEALS.FileNavigator.thumbsLoaded", function() {
        const thumbsColumn  = $("#file-navigator-thumbnail-column");
        const viewerColumn  = $("#file-navigator-viewer-column");

        const updateHeight = function() {
            const navigatorHeight = window.innerHeight - 100;
            navigator.css("height", navigatorHeight + "px");
            const isFooterExisting = thumbsColumn.find("#file-navigator-thumbnail-column-footer").length > 0;
            const footerHeight     = FOOTER_HEIGHT - (isFooterExisting ? 0 : FOOTER_HEIGHT);
            thumbsColumn.find("#file-navigator-thumbnail-content").css("height", (navigatorHeight - footerHeight) + "px");
            thumbsColumn.find("#file-navigator-thumbnail-column-footer").css("height", footerHeight + "px");
            viewerColumn.find("#file-navigator-viewer-header").css("height", HEADER_HEIGHT + "px");
            viewerColumn.find("#file-navigator-viewer-content").css("height", (navigatorHeight - HEADER_HEIGHT) + "px");
            viewerColumn.find("#file-navigator-viewer-content img").css("max-height", (navigatorHeight - HEADER_HEIGHT) + "px");
        };

        updateHeight();

        $(window).on("resize", function() {
            updateHeight();
        });

        var currentBitstreamID;
        const attachEventListeners = function() {
            $("button#more-info").on("click", function() {
                const infoDiv = $("#file-navigator-viewer-info");
                if (infoDiv.is(":visible")) {
                    $(this).html("<i class=\"fa fa-info-circle\"></i> More Info");
                    infoDiv.hide();
                } else {
                    $(this).html("<i class=\"fa fa-times\"></i> Hide Info");
                    infoDiv.css("display", "flex");
                }
            });
        };

        const focus = function(thumb) {
            const item_id      = thumb.data("item-id");
            const bitstream_id = thumb.data("bitstream-id");
            if (bitstream_id === currentBitstreamID) {
                return;
            }
            currentBitstreamID = bitstream_id;
            viewerColumn.html(IDEALS.Spinner());
            thumb.siblings().removeClass("selected");
            thumb.addClass("selected");
            thumb.focus();

            const url = ROOT_URL + "/items/" + item_id + "/bitstreams/" +
                bitstream_id + "/viewer";
            $.ajax({
                method: "GET",
                url: url,
                success: function(data) {
                    viewerColumn.html(data);
                    attachEventListeners();
                    updateHeight();
                    navigator.trigger("IDEALS.FileNavigator.fileChanged");
                },
                error: function(data, status, xhr) {
                    $("#file-navigator-viewer-column .spinner-border").hide();
                    viewerColumn.html("<div id='file-navigator-viewer-error'>" +
                        "<p>There was an error retrieving this file.</p></div>");
                }
            });
        };

        navigator.find("#file-navigator-thumbnail-column .thumbnail").on("keydown", function(e) {
            const thumb = $(this);
            switch (e.keyCode) {
                case 37: // left arrow
                    focus(thumb.prev());
                    break;
                case 39: // right arrow
                    focus(thumb.next());
                    break;
            }
        });

        const thumbs = navigator.find("#file-navigator-thumbnail-column .thumbnail");
        thumbs.on("click", function() {
            const thumb = $(this);
            focus(thumb);
        });

        // Select the primary bitstream, if one is set. Otherwise, select the
        // first one.
        let thumbToSelect = thumbs.filter("[data-primary=true]");
        if (thumbToSelect.length < 1) {
            thumbToSelect = thumbs.filter(":first");
        }
        thumbToSelect.trigger("click");

        // Wire up the download counts button.
        $(".download-counts").on("click", function() {
            const id  = $(this).data("item-id");
            const url = ROOT_URL + "/items/" + id + "/statistics";
            $.get(url, function(data) {
                const dl_counts_modal = $("#download-counts-modal");
                dl_counts_modal.find(".modal-body").html(data);

                const panel_content = $("#download-counts-xhr-content");
                const form          = $("#download-counts-form");

                const refreshContent = function() {
                    const url = ROOT_URL + "/items/" + id + "/download-counts?" +
                        form.serialize();
                    $.get(url, function(data) {
                        panel_content.prev().hide(); // hide the spinner
                        panel_content.html(data);
                        const canvas    = $("#download-chart");
                        const chartData = $.parseJSON($("#chart-data").val());
                        const color     = $("[name=chart_color]").val();
                        new IDEALS.Chart(canvas, chartData, color);
                    });
                };

                refreshContent();

                form.find("input[type=submit]").on("click", function() {
                    // Remove existing content and show the spinner
                    panel_content.empty();
                    panel_content.prev().show(); // show the spinner
                    refreshContent();
                    return false;
                });
            });
        });
    });

};

/**
 * Handles show-item view (/items/:id).
 *
 * @constructor
 */
const ItemView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    new IDEALS.CopyButton($(".copy"), $(".permalink"));

    new FileNavigator();
    const file_navigator = $("#file-navigator");

    file_navigator.on("IDEALS.FileNavigator.thumbsLoaded", function() {
        const modal      = $("#download-all-files-modal");
        const modal_body = modal.find(".modal-body");
        // Clear any previous modal content when the modal is opened.
        modal_body.on("show.bs.modal", function() {
            $(this).html("");
        });
        $(".download-all-files").on("click", function() {
            const item_id = $(this).data("item-id");
            // Initiate the download on the server. This will redirect to a
            // download status page which will get inserted into the modal body.
            const url = ROOT_URL + "/items/" + item_id + "/bitstreams.zip";
            $.get(url, function(data) {
                new IDEALS.DownloadPanel(modal_body, data);
            });
        });
    });
    file_navigator.on("IDEALS.FileNavigator.fileChanged", function() {
        /* See BitstreamsHelper.pdf_object_viewer_for() for why this is commented out
        const pdfjsViewer     = $("#pdfjs-pdf-viewer");
        const nativePDFViewer = $("#native-pdf-viewer");
        if (IDEALS.Util.isPDFSupportedNatively()) {
            pdfjsViewer.hide();
            nativePDFViewer.show();
        } else {
            pdfjsViewer.show();
            nativePDFViewer.hide();
        }
        */
        $(this).find(".edit-bitstream").on("click", function() {
            const item_id      = $(this).data("item-id");
            const bitstream_id = $(this).data("bitstream-id");
            const url          = ROOT_URL + "/items/" + item_id +
                "/bitstreams/" + bitstream_id + "/edit";
            $.get(url, function(data) {
                $("#edit-bitstream-modal .modal-body").html(data);
            });
        });
    });

    // XHR modals
    $(".withdraw").on("click", function() {
        const id  = $(this).data("item-id");
        const url = ROOT_URL + "/items/" + id + "/edit-withdrawal";
        $.get(url, function(data) {
            const modal = $("#withdraw-modal");
            modal.find(".modal-body").html(data);
            modal.modal("show");
        });
    });
    $(".edit-item-embargoes").on("click", function() {
        const id  = $(this).data("item-id");
        const url = ROOT_URL + "/items/" + id + "/edit-embargoes";

        $.get(url, function(data) {
            const modalBody = $("#edit-item-embargoes-modal .modal-body");
            modalBody.html(data);

            const updateEmbargoIndices = function() {
                modalBody.find(".card").each(function(index, element) {
                    $(element).find("input, select").each(function() {
                        const input = $(this);
                        const newId = input.attr("id")
                            .replace(/_[0-9]_/, "_" + index + "_");
                        const newName = input.attr("name")
                            .replace(/\[[0-9]]/, "[" + index + "]");
                        input.attr("id", newId);
                        input.attr("name", newName);
                    });
                });
            };
            updateEmbargoIndices();
            const onAddEmbargoClicked = function() {
                const lastEmbargo = modalBody.find(".card:last");
                const newEmbargo  = lastEmbargo.clone();
                lastEmbargo.after(newEmbargo);
                newEmbargo.show();
                updateEmbargoIndices();
                newEmbargo.find(".remove-embargo").on("click", onRemoveEmbargoClicked);
                newEmbargo.find(".remove-user-group").on("click", onRemoveUserGroupClicked);
                newEmbargo.find(".add-user-group").on("click", onAddUserGroupClicked);
            };
            const onRemoveEmbargoClicked = function() {
                const cardToRemove = $(this).parents(".card");
                if (modalBody.find(".card").length > 1) {
                    cardToRemove.remove();
                    updateEmbargoIndices();
                } else {
                    cardToRemove.hide();
                    cardToRemove.find("input, select, textarea").prop("disabled", true);
                    cardToRemove.find("input[type=checkbox]").prop("checked", false);
                }
            };
            modalBody.find(".remove-embargo").on("click", onRemoveEmbargoClicked);
            modalBody.find(".add-embargo").on("click", onAddEmbargoClicked);

            const onAddUserGroupClicked = function() {
                const lastUserGroup = $(this).parents(".mb-3").find(".user-group:last");
                const newUserGroup  = lastUserGroup.clone();
                lastUserGroup.after(newUserGroup);
                newUserGroup.show();
                newUserGroup.find("select").prop("disabled", false);
                newUserGroup.find(".remove-user-group").on("click", onRemoveUserGroupClicked);
            };
            const onRemoveUserGroupClicked = function() {
                const containersToRemove = $(this).parents(".user-group");
                if (containersToRemove.length > 1) {
                    containersToRemove.remove();
                } else {
                    containersToRemove.hide();
                    containersToRemove.find("select").prop("disabled", true);
                }
            };
            modalBody.find(".remove-user-group").on("click", onRemoveUserGroupClicked);
            modalBody.find(".add-user-group").on("click", onAddUserGroupClicked);
        });
    });
    $(".edit-item-membership").on("click", function() {
        const id  = $(this).data("item-id");
        const url = ROOT_URL + "/items/" + id + "/edit-membership";
        $.get(url, function(data) {
            $("#edit-item-membership-modal .modal-body").html(data);
            new IDEALS.CollectionSelectMenus();
        });
    });
    $(".edit-item-metadata").on("click", function() {
        const id  = $(this).data("item-id");
        const url = ROOT_URL + "/items/" + id + "/edit-metadata";
        $.get(url, function(data) {
            $("#edit-item-metadata-modal .modal-body").html(data);
            new IDEALS.MetadataEditor();
        });
    });
    $(".edit-item-properties").on("click", function() {
        const id  = $(this).data("item-id");
        const url = ROOT_URL + "/items/" + id + "/edit-properties";
        $.get(url, function(data) {
            $("#edit-item-properties-modal .modal-body").html(data);
        });
    });
    $(".manage-item-files").on("click", function() {
        const id  = $(this).data("item-id");
        const url = ROOT_URL + "/items/" + id + "/upload-bitstreams";
        $.get(url, function(data) {
            const modal = $("#manage-item-files-modal");
            modal.find(".modal-body").html(data);
            // Reload the page in order to refresh the file list.
            modal.on("hidden.bs.modal", function() {
                window.location.reload();
            });
            new IDEALS.ItemFileUploader();
        });
    });
};

/**
 * Handles review-items view (/items/review).
 *
 * @constructor
 */
const ReviewItemsView = function() {
    new IDEALS.CheckAllButton($('.check-all'),
                              $('#items input[type=checkbox]'));
    const form = $('form#review-form');
    const verb = form.find("[name=verb]");
    $('.approve-checked').on('click', function() {
        verb.val("approve");
        form.submit();
    });
    $('.reject-checked').on('click', function() {
        verb.val("reject");
        form.submit();
    });
};

/**
 * Handles export-items view (/items/export).
 *
 * @constructor
 */
const ExportItemsView = function() {
    new IDEALS.CheckAllButton(
        $("button#check-all"),
        $("input[name='elements[]']"));
};

$(document).ready(function() {
    if ($("body#list_items").length) {
        new ItemsView();
    } else if ($("body#show_item").length) {
        new ItemView();
    } else if ($("body#review_items").length) {
        new ReviewItemsView();
    } else if ($("body#export_items").length) {
        new ExportItemsView();
    }
});
