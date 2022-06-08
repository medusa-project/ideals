##
# Concern to be included by models that get indexed in Elasticsearch. Provides
# almost all of the functionality they need except for {as_indexed_json}, which
# must be overridden.
#
# # What gets indexed?
#
# Any entity that will appear in results that:
#
# 1. Are faceted
# 2. Are natural- or relevance-sorted
# 3. Are field-weighted
# 4. Would require a complicated/impossible SQL query
# 5. Need better performance than the database can provide
#
# # Querying
#
# A low-level interface to Elasticsearch is provided by [ElasticsearchClient],
# but in most cases, it's easier to use the higher-level query interface
# provided by the various [AbstractRelation] subclasses.
#
# # Persistence callbacks
#
# Documents are automatically submitted to Elasticsearch (see
# {as_indexed_json}) upon transaction commit. They are **not** sent upon save
# or destroy. Whenever creating, updating, or deleting outside of a
# transaction, you must {reindex reindex} or {delete_document delete} the
# document manually.
#
# # How Elasticsearch interaction works in the application
#
# There are two layers of Elasticsearch interaction:
#
# 1. [ElasticsearchClient] handles all of the HTTP communication. Although this
#    alone would be enough to communicate with Elasticsearch, the queries that
#    are needed tend to be quite complex, so another layer exists to help with
#    that:
# 2. [AbstractRelation] subclasses enable query construction and results
#    marshaling in the manner of [ActiveRecord::Relation] on model objects
#    that include this module. They use [ElasticsearchClient] behind the
#    scenes.
#
# # Author's note
#
# Why is a custom client solution used instead of the official Elastic Ruby
# gems? This application needs fine-grained control over searching, and I am
# worried about obscuring the communication between it and Elasticsearch behind
# a complicated and perhaps poorly documented & supported glue layer. This
# system also provides a nicer interface to ES than Elastic's gems, which
# require clients to understand ES concepts to construct their queries, which
# are hardly trivial. Also, this application is hosted in AWS, which has
# recently forked ES into its own OpenSearch product, which is not guaranteed
# to remain compatible with Elastic's gems and does not have a friendly gem of
# its own.
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
      relation    = search
      count       = relation.count
      progress    = Progress.new(count)
      index       = 0
      num_deleted = 0

      relation.each_id_in_batches do |id|
        unless class_.exists?(id: to_model_id(id))
          class_.delete_document(id)
          num_deleted += 1
        end
        index += 1
        progress.report(index, "Deleting orphaned documents")
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
    after_commit :reindex, on: [:create, :update],
                 if: -> { !DspaceImporter.instance.running? }
    after_commit -> { self.class.delete_document(index_id) }, on: :destroy,
                 if: -> { !DspaceImporter.instance.running? }

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
