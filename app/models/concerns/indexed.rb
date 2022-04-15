##
# Concern to be included by models that get indexed in Elasticsearch. Provides
# almost all of the functionality they need except for {as_indexed_json}, which
# must be overridden.
#
# # What Gets Indexed?
#
# Any entity that needs to appear in results that:
#
# 1. Are faceted
# 2. Are natural- or relevance-sorted
# 3. Would require a complicated/impossible SQL query
# 4. Need better performance than the database can provide
#
# # Querying
#
# A low-level interface to Elasticsearch is provided by {ElasticsearchClient},
# but in most cases, it's easier to use the higher-level query interface
# provided by the various {AbstractRelation} subclasses.
#
# # Persistence Callbacks
#
# **IMPORTANT NOTE**: Instances are automatically indexed in Elasticsearch (see
# {as_indexed_json}) upon transaction commit. They are **not** indexed upon
# save or destroy. Whenever creating, updating, or deleting outside of a
# transaction, you must {reindex reindex} or {delete_document delete} the
# document manually.
#
module Indexed
  extend ActiveSupport::Concern

  class_methods do
    ##
    # Normally this method should not be used except to delete "orphaned"
    # documents with no database counterpart, which theoretically should never
    # exist.
    #
    def delete_document(id)
      query = {
          query: {
              bool: {
                  filter: [
                      {
                          term: {
                              ElasticsearchIndex::StandardFields::ID => id
                          }
                      }
                  ]
              }
          }
      }
      ElasticsearchClient.instance.delete_by_query(JSON.generate(query))
    end

    ##
    # Iterates through all of the model's indexed documents and deletes any for
    # which no counterpart exists in the database.
    #
    # This is very expensive and ideally it should never have to be used.
    #
    def delete_orphaned_documents
      class_ = name.constantize

      # Get the document count.
      relation = search.limit(0)
      count    = relation.count
      progress = Progress.new(count)

      # Retrieve document IDs in batches.
      index = start = num_deleted = 0
      limit = 1000
      while start < count do
        ids = relation.start(start).limit(limit).to_id_a
        ids.each do |id|
          unless class_.exists?(id: to_model_id(id))
            class_.delete_document(id)
            num_deleted += 1
          end
          index += 1
          progress.report(index, "Deleting orphaned documents")
        end
        start += limit
      end
      puts "\nDeleted #{num_deleted} documents"
    end

    ##
    # Reindexes all of the class' indexed documents. Multi-threaded indexing is
    # supported to potentially make this go faster, but care must be taken not
    # to overwhelm the Elasticsearch cluster, which will knock it into a
    # read-only mode.
    #
    # N.B. 1: Cursory testing suggests that benefit diminishes rapidly beyond 2
    # threads.
    #
    # N.B. 2: Orphaned documents are not deleted; for that, use
    # {delete_orphaned_documents}.
    #
    # @param es_index [String] Index name. If omitted, the default index is
    #                          used.
    # @param num_threads [Integer]
    # @return [void]
    #
    def reindex_all(es_index: nil, num_threads: 1)
      ThreadUtils.process_in_parallel(all.order(:id),
                                      num_threads:    num_threads,
                                      print_progress: true) do |model|
        model.reindex(es_index)
      end
    end

    ##
    # @return [AbstractRelation] Instance of one of the {AbstractRelation}
    #                            subclasses.
    #
    def search
      "#{name}Relation".constantize.new
    end

    ##
    # @param index_id [String] Indexed document ID.
    # @return [Integer] ID of the instance in the database.
    #
    def to_model_id(index_id)
      index_id.split(":").last
    end
  end

  included do
    after_commit :reindex, on: [:create, :update]
    after_commit -> { self.class.delete_document(index_id) }, on: :destroy

    ##
    # @return [Hash] Indexable representation of the instance to be serialized
    #                as JSON. Most importantly, a
    #                {ElasticsearchIndex::StandardFields::CLASS} key is
    #                included.
    #
    def as_indexed_json
      raise 'Including classes must override as_indexed_json()'
    end

    ##
    # @return [String] ID of the instance's indexed document.
    #
    def index_id
      "#{self.class.name.downcase}:#{self.id}"
    end

    ##
    # @param index [String] Index name. If omitted, the default index is used.
    # @return [void]
    #
    def reindex(index = nil)
      index ||= Configuration.instance.elasticsearch[:index]
      ElasticsearchClient.instance.index_document(index,
                                                  self.index_id,
                                                  self.as_indexed_json)
    end
  end

end
