# frozen_string_literal: true

##
# Encapsulates an OpenSearch index.
#
# The application uses only one index. Its name is arbitrary. The application
# can be pointed directly at the index, or to an alias of the index, using the
# `OpenSearch/index` configuration key.
#
# # Index migration
#
# OpenSearch index schemas can't (for the most part) be changed in place,
# so when a change is needed, a new index must be created. This involves
# modifying `app/search/index_schema.yml` and running the
# `OpenSearch:indexes:create` rake task.
#
# Once created, it must be populated with documents. If the documents in the
# old index are compatible with the new index, then this is a simple matter of
# running the `opensearch:indexes:reindex` rake task. Otherwise, all
# database entities need to be reindexed into the new index. This is more time-
# consuming and involves the `opensearch:reindex` rake task.
#
# Once the new index has been populated, either the application's
# `opensearch/index` configuration key must be updated to point to it, or
# else an index alias must be created that matches the value of that key.
#
class OpenSearchIndex

  ##
  # Standard fields present in all or most documents.
  #
  class StandardFields
    ALL_ELEMENTS     = "lt_all_elements"
    CLASS            = "k_class"
    CREATED          = "d_created"
    # Only item documents may have this.
    FULL_TEXT        = "lt_full_text"
    # Contains the value of {Indexed#index_id()}.
    ID               = "_id"
    INSTITUTION_KEY  = "k_institution_key"
    INSTITUTION_NAME = "k_institution_name"
    LAST_INDEXED     = "d_last_indexed"
    LAST_MODIFIED    = "d_last_modified"
    # Relevance score in a returned document.
    SCORE            = "_score"
    # Many fields get copied into this field automatically by ES, but its use
    # is frowned upon because it does not respect
    # {MetadataProfileElement#relevance_weight field weights}, and it also
    # contains irrelevant and potentially unauthorized text. {ALL_ELEMENTS}
    # would generally be used instead, and we should probably reevaluate
    # whether we even need this field.
    SEARCH_ALL       = "search_all"
  end

  ##
  # Field values should be truncated to this length.
  # (32766 total / 3 bytes per character)
  #
  MAX_KEYWORD_FIELD_LENGTH = 10922

  ##
  # Default is 10,000. This should remain in sync with the same value in the
  # schema YAML.
  #
  MAX_RESULT_WINDOW = 10000

  # ES has trouble with far distant years.
  MAX_YEAR = 2500

  SCHEMA   = YAML.load_file(File.join(Rails.root, 'app', 'search', 'index_schema.yml'))

end