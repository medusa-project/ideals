/**
 * Handles list-items view (/items).
 *
 * @constructor
 */
const ItemsView = function() {
    new IDEALS.FacetSet().init();
};

/**
 * Controls the file navigator in item view.
 *
 * Events:
 *
 * * `IDEALS.FileNavigator.fileChanged`
 *
 * @constructor
 */
const FileNavigator = function() {
    const HEADER_HEIGHT = 50;
    const FOOTER_HEIGHT = 50;
    const ROOT_URL      = $('input[name="root_url"]').val();
    const navigator     = $("#file-navigator");
    const thumbsColumn  = $("#file-navigator-thumbnail-column");
    const viewerColumn  = $("#file-navigator-viewer-column");

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
                updateHeight();
                attachEventListeners();
                navigator.trigger("IDEALS.FileNavigator.fileChanged");
            },
            error: function(data, status, xhr) {
                $("#file-navigator-viewer-column .spinner-border").hide();
                viewerColumn.html("<div id='file-navigator-viewer-error'><p>There was an error retrieving this file.</p></div>");
            }
        });
    };

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

    navigator.find("#file-navigator-thumbnail-column .thumbnail").on("click", function() {
        const thumb = $(this);
        focus(thumb);
    }).filter(":first").trigger("click");
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
    $("#file-navigator").on("IDEALS.FileNavigator.fileChanged", function() {
        $(this).find(".edit-bitstream").on("click", function() {
            const item_id      = $(this).data("item-id");
            const bitstream_id = $(this).data("bitstream-id");
            const url          = ROOT_URL + "/items/" + item_id + "/bitstreams/" +
                bitstream_id + "/edit";
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
                    cardToRemove.find("input[type=checkbox]").prop("checked", false);
                }
            };
            modalBody.find(".remove-embargo").on("click", onRemoveEmbargoClicked);
            modalBody.find(".add-embargo").on("click", onAddEmbargoClicked);

            const onAddUserGroupClicked = function() {
                const lastUserGroup = $(this).parents(".form-group").find(".user-group:last");
                const newUserGroup  = lastUserGroup.clone();
                lastUserGroup.after(newUserGroup);
                newUserGroup.show();
                newUserGroup.find("select").attr("disabled", false);
                newUserGroup.find(".remove-user-group").on("click", onRemoveUserGroupClicked);
            };
            const onRemoveUserGroupClicked = function() {
                const containersToRemove = $(this).parents(".user-group");
                if (containersToRemove.length > 1) {
                    containersToRemove.remove();
                } else {
                    containersToRemove.hide();
                    containersToRemove.find("select").attr("disabled", true);
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
    // Loads content into the Download Counts panel
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
                    new IDEALS.Chart(canvas, chartData);
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
    $(".upload-item-files").on("click", function() {
        const id  = $(this).data("item-id");
        const url = ROOT_URL + "/items/" + id + "/upload-bitstreams";
        $.get(url, function(data) {
            const modal = $("#upload-item-files-modal");
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
