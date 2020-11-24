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
