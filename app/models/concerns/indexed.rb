##
# Concern to be included by models that get indexed in OpenSearch. Provides
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
# 4. Require fine-grained control over query processing
# 5. Would require a complicated/impossible SQL query
# 6. Need better performance than the database can provide
#
# **All** models of a particular class get indexed, including buried ones,
# embargoed ones, etc.
#
# # Querying
#
# A low-level interface to OpenSearch is provided by {OpenSearchClient},
# but in most cases, it's easier to use the higher-level query interface
# provided by the various {AbstractRelation} subclasses.
#
# # Persistence callbacks
#
# Documents are automatically submitted to OpenSearch (see
# {as_indexed_json}) upon transaction commit. They are **not** sent upon save
# or destroy. Whenever creating, updating, or deleting outside of a
# transaction, you must {reindex reindex} or {delete_document delete} the
# document manually. (If you make a mistake here, you can use {index_unindexed}
# to rectify it.)
#
# This behavior has implications for batch processing. When updating large
# numbers of indexed models, it is common to use a technique like
# {ActiveRecord::Base#find_each} to iterate over them in batches, wrapping that
# in an {ActiveRecord::Base#uncached} block. Transactions will disable the
# latter block and defeat the memory efficiency of the former block by causing
# all loaded instances to get cached in memory. Transactions, therefore, tend
# to be a bad idea when batch-processing.
#
# # How OpenSearch interaction works in the application
#
# There are two layers of OpenSearch interaction:
#
# 1. {OpenSearchClient} handles all of the HTTP communication. Although this
#    alone would be enough to communicate with OpenSearch, the queries that
#    are needed tend to be quite complex, so another layer exists to help with
#    that:
# 2. {AbstractRelation} subclasses enable query construction and results
#    marshaling in the manner of {ActiveRecord::Relation} on model objects
#    that include this module. They use {OpenSearchClient} behind the
#    scenes.
#
# # Author's note
#
# Why is a custom client solution used instead of the official Elastic Ruby
# gems? This application needs fine-grained control over searching, and I am
# worried about obscuring the communication between it and OpenSearch behind
# a complicated and perhaps poorly documented & supported glue layer. This
# system also provides a nicer interface to ES than Elastic's gems, which
# require clients to understand ES concepts to construct their queries, which
# are hardly trivial. Also, this application is hosted in AWS, which has
# recently forked ES into its own OpenSearch product, which is not guaranteed
# to remain compatible with Elastic's gems. Although AWS publishes its own SDK
# for OpenSearch, all of the same concerns apply.
#
module Indexed
  extend ActiveSupport::Concern

  class_methods do
    ##
    # Indexes all of the class' models using the
    # [Bulk API](https://opensearch.org/docs/1.2/opensearch/rest-api/document-apis/bulk/).
    # This is faster than indexing them all individually using {reindex_all}.
    #
    # Orphaned documents are not deleted; for that, use
    # {delete_orphaned_documents}.
    #
    # @return [void]
    # @see reindex_all
    #
    def bulk_reindex
      batch_size  = 500 # play around to find an ideal size
      offset      = 0
      count       = all.count
      client      = OpenSearchClient.instance
      index_name  = Configuration.instance.opensearch[:index]
      progress    = Progress.new(count)
      num_indexed = 0

      uncached do
        while offset + batch_size < count + batch_size do
          progress.report(offset, "Bulk-indexing #{count} #{to_s} documents")
          models = all.order(:id).limit(batch_size).offset(offset)
          lines = []
          models.each do |model|
            lines << JSON.generate({ index: { "_id": model.index_id }})
            lines << model.as_indexed_json
            num_indexed += 1
          end
          lines << ""
          ndjson = lines.join("\n")
          client.bulk_index(index_name, ndjson)
          offset += batch_size
        end
      end
    end

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
                  OpenSearchIndex::StandardFields::ID => id
                }
              }
            ]
          }
        }
      }
      OpenSearchClient.instance.delete_by_query(JSON.generate(query))
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
        unless class_.exists?(id: id)
          class_.delete_document(to_index_id(name, id))
          num_deleted += 1
        end
        index += 1
        progress.report(index, "Deleting orphaned documents")
      end
      puts "\nDeleted #{num_deleted} documents"
    end

    ##
    # Indexes all database entities that aren't already indexed. This achieves
    # the same result as {#reindex_all}, but much more efficiently, when it is
    # known that the schema hasn't changed since the last time {#reindex_all}
    # was run.
    #
    def index_unindexed
      batch_size  = 1000
      offset      = 0
      count       = all.count
      client      = OpenSearchClient.instance
      index_name  = Configuration.instance.opensearch[:index]
      progress    = Progress.new(count)
      num_indexed = 0

      uncached do
        while offset + batch_size < count + batch_size do
          progress.report(offset, "Indexing unindexed #{to_s} documents")
          models = all.order(:id).limit(batch_size).offset(offset)
          models.each do |model|
            unless client.document_exists?(index_name, model.index_id)
              model.reindex
              num_indexed += 1
            end
          end
          offset += batch_size
        end
      end
    end

    ##
    # Individually reindexes all of the class' indexed documents.
    # Multi-threaded indexing is supported to potentially make this go faster,
    # but care must be taken not to overwhelm the OpenSearch cluster, which
    # will knock it into a read-only mode.
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
    # @param rescue_errors [Boolean]
    # @return [void]
    # @see bulk_reindex
    #
    def reindex_all(es_index: nil, num_threads: 1, rescue_errors: false)
      ThreadUtils.process_in_parallel(all.order(:id),
                                      num_threads:    num_threads,
                                      rescue_errors:  rescue_errors,
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
    # @param class_name [String]
    # @param model_id [Integer]
    # @return [String]
    #
    def to_index_id(class_name, model_id)
      [class_name.downcase, model_id].join(":")
    end

    ##
    # @param index_id [String] Indexed document ID.
    # @return [Integer] ID of the instance in the database.
    #
    def to_model_id(index_id)
      index_id.split(":").last.to_i
    end
  end

  included do
    after_commit :reindex, on: [:create, :update]
    after_commit -> { self.class.delete_document(index_id) }, on: :destroy

    ##
    # @return [Hash] Indexable representation of the instance to be serialized
    #                as JSON. Most importantly, a
    #                {OpenSearchIndex::StandardFields::CLASS} key is
    #                included.
    #
    def as_indexed_json
      raise 'Including classes must override as_indexed_json()'
    end

    ##
    # @return [String] ID of the instance's indexed document.
    #
    def index_id
      to_index_id(self.class.name, self.id)
    end

    ##
    # @return [Hash] The currently indexed document.
    #
    def indexed_document
      index ||= Configuration.instance.opensearch[:index]
      OpenSearchClient.instance.get_document(index,
                                             self.index_id)
    end

    ##
    # @param index [String] Index name. If omitted, the default index is used.
    # @return [void]
    #
    def reindex(index = nil)
      index ||= Configuration.instance.opensearch[:index]
      OpenSearchClient.instance.index_document(index,
                                               self.index_id,
                                               self.as_indexed_json)
    end
  end

end
