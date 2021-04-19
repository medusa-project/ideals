/**
 * Handles list-items view (/items).
 *
 * @constructor
 */
const ItemsView = function() {
    new IDEALS.FacetSet().init();
};

/**
 * Handles show-item view (/items/:id).
 *
 * @constructor
 */
const ItemView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    new IDEALS.CopyButton($(".copy"), $(".permalink"));

    // XHR modals
    $(".edit-bitstream").on("click", function() {
        const item_id      = $(this).data("item-id");
        const bitstream_id = $(this).data("bitstream-id");
        const url          = ROOT_URL + "/items/" + item_id + "/bitstreams/" +
            bitstream_id + "/edit";
        $.get(url, function(data) {
            $("#edit-bitstream-modal .modal-body").html(data);
        });
    });
    $(".edit-item-embargoes").on("click", function() {
        const id  = $(this).data("item-id");
        const url = ROOT_URL + "/items/" + id + "/edit-embargoes";

        $.get(url, function(data) {
            const modalBody = $("#edit-item-embargoes-modal .modal-body");
            modalBody.html(data);
            const table = modalBody.find("table");

            const updateRowIndices = function() {
                table.find("tbody > tr").each(function(index, element) {
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
            const onRemove = function() {
                if (table.find("tbody > tr").length > 1) {
                    $(this).parents("tr").remove();
                    updateRowIndices();
                }
            };
            modalBody.find(".remove").on("click", onRemove);
            modalBody.find(".add").on("click", function() {
                const lastEmbargo = table.find("tr:last");
                const newEmbargo = lastEmbargo.clone();
                lastEmbargo.after(newEmbargo);
                updateRowIndices();
                newEmbargo.find(".remove").on("click", onRemove);
            });
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

            const refreshTable = function() {
                const url = ROOT_URL + "/items/" + id + "/download-counts?" +
                    form.serialize();
                $.get(url, function(data) {
                    panel_content.prev().hide(); // hide the spinner
                    panel_content.html(data);
                });
            };

            refreshTable();

            form.find("input[type=submit]").on("click", function() {
                // Remove existing content and show the spinner
                panel_content.empty();
                panel_content.prev().show(); // show the spinner
                refreshTable();
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

$(document).ready(function() {
    if ($("body#list_items").length) {
        new ItemsView();
    } else if ($("body#show_item").length) {
        new ItemView();
    } else if ($("body#review_items").length) {
        new ReviewItemsView();
    }
});
