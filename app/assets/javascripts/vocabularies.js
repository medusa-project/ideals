const Vocabularies = {

    AddVocabularyClickHandler: function() {
        const ROOT_URL      = $('input[name="root_url"]').val();
        const institutionID = $("[name=institution_id]").val();
        const url           = ROOT_URL + "/vocabularies/new?" +
            "vocabulary%5Binstitution_id%5D=" + institutionID;
        $.get(url, function(data) {
            $("#add-vocabulary-modal .modal-body").html(data);
        });
    },

    EditVocabularyClickHandler: function() {
        const ROOT_URL     = $('input[name="root_url"]').val();
        const vocabularyID = $(this).data("vocabulary-id");
        const url          = ROOT_URL + "/vocabularies/" + vocabularyID +
            "/edit";
        $.get(url, function(data) {
            $("#edit-vocabulary-modal .modal-body").html(data);
        });
    },

    /**
     * Handles list-vocabularies view (/vocabularies).
     */
    VocabulariesView: function() {
        $('button.add-vocabulary').on("click",
            Vocabularies.AddVocabularyClickHandler);
        $('button.edit-vocabulary').on("click",
            Vocabularies.EditVocabularyClickHandler);
    },

    /**
     * Handles show-vocabulary view (/vocabularies/:id).
     */
    VocabularyView: function() {
        const ROOT_URL = $('input[name="root_url"]').val();

        $('button.edit-vocabulary').on("click",
            Vocabularies.EditVocabularyClickHandler);
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
        $("button.import-terms").on("click", function() {
            const vocabulary_id = $(this).data("vocabulary-id");
            const url           = ROOT_URL + "/vocabularies/" + vocabulary_id +
                "/terms/import";
            $.get(url, function(data) {
                $("#import-terms-modal .modal-body").html(data);
            });
        });
    }

};

$(document).ready(function() {
    if ($('body#vocabularies').length) {
        new Vocabularies.VocabulariesView();
    } else if ($("body#show_vocabulary").length) {
        new Vocabularies.VocabularyView();
    }
});
