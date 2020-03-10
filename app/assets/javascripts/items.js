/**
 * Handles the deposit agreement view.
 *
 * @constructor
 */
const DepositView = function() {
    // Show the deposit agreement when the begin-submission button is clicked.
    $("button.begin-submission").on("click", function() {
        $(this).parents(".card").fadeOut(IDEALS.FADE_TIME, function() {
            $("#deposit-agreement").fadeIn(IDEALS.FADE_TIME);
        });
    });
};

/**
 * Handles the edit-item view used during submission.
 *
 * @constructor
 */
const EditView = function() {
    $("button.step-1-to-2").on("click", function() {
        $("#metadata-tab").tab("show");
    });
    $("button.step-2-to-3").on("click", function() {
        $("#files-tab").tab("show");
    });
    $("button.step-3-to-2").on("click", function() {
        $("#metadata-tab").tab("show");
    });
    $("button.step-2-to-1").on("click", function() {
        $("#properties-tab").tab("show");
    });
    new IDEALS.DepositMetadataEditor();

    $("input, select, textarea").on("change", function() {
        console.log("form changed");
    });
};

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

$(document).ready(function() {
    if ($("body#deposit").length) {
        new DepositView();
    } else if ($("body#edit_item")) {
        new EditView();
    } else if ($("body#list_items").length) {
        new ItemsView();
    } else if ($("body#show_item").length) {
        new ItemView();
    }
});
