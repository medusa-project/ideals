/**
 * Handles list-vocabularies view (/vocabularies).
 *
 * @constructor
 */
const VocabulariesView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    $('button.add-vocabulary').on("click", function() {
        const url = ROOT_URL + "/vocabularies/new";
        $.get(url, function(data) {
            $("#add-vocabulary-modal .modal-body").html(data);
        });
    });
    $('button.edit-vocabulary').on("click", function() {
        const vocabulary_id = $(this).data("vocabulary-id");
        const url           = ROOT_URL + "/vocabularies/" + vocabulary_id + "/edit";
        $.get(url, function(data) {
            $("#edit-vocabulary-modal .modal-body").html(data);
        });
    });
};

/**
 * Handles show-vocabulary view (/vocabularies/:id).
 *
 * @constructor
 */
const VocabularyView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    $('button.edit-vocabulary').on("click", function() {
        const vocabulary_id = $(this).data("vocabulary-id");
        const url           = ROOT_URL + "/vocabularies/" + vocabulary_id + "/edit";
        $.get(url, function(data) {
            $("#edit-vocabulary-modal .modal-body").html(data);
        });
    });
    $("button.add-term").on("click", function() {
        const vocabulary_id = $(this).data("vocabulary-id");
        const url           = ROOT_URL + "/vocabularies/" + vocabulary_id + "/terms/new";
        $.get(url, function(data) {
            $("#add-term-modal .modal-body").html(data);
        });
    });
    $("button.edit-term").on("click", function() {
        const vocabulary_id = $(this).data("vocabulary-id");
        const term_id       = $(this).data("term-id");
        const url           = ROOT_URL + "/vocabularies/" + vocabulary_id +
            "/terms/" + term_id + "/edit";
        $.get(url, function(data) {
            $("#edit-term-modal .modal-body").html(data);
        });
    });
};

$(document).ready(function() {
    if ($('body#vocabularies').length) {
        new VocabulariesView();
    } else if ($("body#show_vocabulary").length) {
        new VocabularyView();
    }
});
