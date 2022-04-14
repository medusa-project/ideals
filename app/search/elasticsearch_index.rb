##
# Encapsulates an Elasticsearch index.
#
# The application uses only one index. Its name is arbitrary. The application
# can be pointed directly at the index, or to an alias of the index, using the
# `elasticsearch/index` configuration key.
#
# # Index migration
#
# Elasticsearch index schemas can't (for the most part) be changed in place,
# so when a change is needed, a new index must be created. This involves
# modifying `app/search/index_schema.yml` and running the
# `elasticsearch:indexes:create` rake task.
#
# Once created, it must be populated with documents. If the documents in the
# old index are compatible with the new index, then this is a simple matter of
# running the `elasticsearch:indexes:reindex` rake task. Otherwise, all
# database entities need to be reindexed into the new index. This is more time-
# consuming and involves the `elasticsearch:reindex` rake task.
#
# Once the new index has been populated, either the application's
# `elasticsearch/index` configuration key must be updated to point to it, or
# else an index alias must be created that matches the value of that key.
#
class ElasticsearchIndex

  ##
  # Standard fields present in all documents.
  #
  class StandardFields
    CLASS           = "k_class"
    CREATED         = "d_created"
    ID              = "_id"
    INSTITUTION_KEY = "k_institution_key"
    LAST_INDEXED    = "d_last_indexed"
    LAST_MODIFIED   = "d_last_modified"
    SCORE           = "_score"
    SEARCH_ALL      = "search_all"
  end

  SCHEMA = YAML.load_file(File.join(Rails.root, 'app', 'search', 'index_schema.yml'))

end