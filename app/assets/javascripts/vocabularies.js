/**
 * Handles list-vocabularies view (/vocabularies).
 */
const VocabulariesView = {

    initialize: function () {
        $('button.add-vocabulary').on("click", function () {
            const ROOT_URL      = $('input[name="root_url"]').val();
            const institutionID = $("[name=institution_id]").val();
            const url           = ROOT_URL + "/vocabularies/new?" +
                "vocabulary%5Binstitution_id%5D=" + institutionID;
            $.get(url, function (data) {
                $("#add-vocabulary-modal .modal-body").html(data);
            });
        });
        $('button.edit-vocabulary').on("click", function () {
            const ROOT_URL     = $('input[name="root_url"]').val();
            const vocabularyID = $(this).data("vocabulary-id");
            const url          = ROOT_URL + "/vocabularies/" + vocabularyID +
                "/edit";
            $.get(url, function (data) {
                $("#edit-vocabulary-modal .modal-body").html(data);
            });
        });
    }

};

/**
 * Handles show-vocabulary view (/vocabularies/:id).
 */
const VocabularyView = {

    initialize: function() {
        const ROOT_URL = $('input[name="root_url"]').val();

        $('button.edit-vocabulary').on("click",
            VocabulariesView.EditVocabularyClickHandler);
        $("button.add-term").on("click", function() {
            const vocabulary_id = $(this).data("vocabulary-id");
            const url           = ROOT_URL + "/vocabularies/" + vocabulary_id +
                "/terms/new";
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
        $("button.import-terms").on("click", function() {
            const vocabulary_id = $(this).data("vocabulary-id");
            const url           = ROOT_URL + "/vocabularies/" + vocabulary_id +
                "/terms/import";
            $.get(url, function(data) {
                $("#import-terms-modal .modal-body").html(data);
            });
        });

        const filterField = $("input[name=q]");
        const refreshResults = function() {
            const form = filterField.parents("form:last");
            console.log(form);
            $.ajax({
                method: "GET",
                url:    form.attr("action"),
                data:   form.serialize(),
                success: function(data) {
                    $("#terms-list").html(data);
                },
                error: function(data, status, xhr) {
                }
            });
        };
        let timeout = null;
        filterField.on("keyup", function() {
            clearTimeout(timeout);
            timeout = setTimeout(refreshResults, IDEALS.UIUtils.KEY_DELAY);
        });
    }

};

$(document).ready(function() {
    if ($("body#vocabularies").length) {
        VocabulariesView.initialize();
    } else if ($("body#show_vocabulary").length) {
        VocabularyView.initialize();
    }
});
