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

    $(".edit-item-membership").on("click", function() {
        const id  = $(this).data("item-id");
        const url = ROOT_URL + "/items/" + id + "/edit-membership";
        $.get(url, function(data) {
            $("#edit-item-membership-modal .modal-body").html(data);
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
};

/**
 * Handles review-items view (/items/review).
 *
 * @constructor
 */
const ReviewItemsView = function() {
    $('.check-all').on('click', function() {
        const checkboxes = $('#items input[type=checkbox]');
        const checked    = ($(this).data('checked') === 'true');
        if (checked) {
            checkboxes.prop('checked', false);
            $(this).data('checked', 'false');
            $(this).html('<i class="far fa-check-square"></i> Check All');
        } else {
            checkboxes.prop('checked', true);
            $(this).data('checked', 'true');
            $(this).html('<i class="far fa-minus-square"></i> Uncheck All');
        }
    });
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
