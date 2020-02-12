##
# Concern to be included by models that get indexed in Elasticsearch. Provides
# almost all of the functionality they need except for {as_indexed_json}, which
# must be overridden.
#
# # Querying
#
# A low-level interface to Elasticsearch is provided by ElasticsearchClient, but
# in most cases, it's better to use the higher-level query interface provided
# by {ItemFinder}, which is easier to use, and takes public accessibility etc.
# into account.
#
# # Persistence Callbacks
#
# **IMPORTANT NOTE**: Instances are automatically indexed in Elasticsearch (see
# {as_indexed_json}) upon transaction commit. They are **not** indexed on
# save or delete. Whenever creating, updating, or deleting outside of a
# transaction, you must {reindex reindex} or {delete_document delete} the
# document manually.
#
module Indexed
  extend ActiveSupport::Concern

  class_methods do
    ##
    # Normally this method should not be used except to delete "orphaned"
    # documents with no database counterpart. See the class documentation for
    # information about correct document deletion.
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
    # This is very expensive and ideally the application should be written in
    # a way that never requires it to be called.
    #
    def delete_orphaned_documents
      class_ = name.constantize
      start_time = Time.now

      # Get the document count.
      finder   = search.limit(0)
      count    = finder.count
      progress = Progress.new(count)

      # Retrieve document IDs in batches.
      index = start = num_deleted = 0
      limit = 1000
      while start < count do
        ids = finder.start(start).limit(limit).to_id_a
        ids.each do |id|
          unless class_.exists?(id: to_model_id(id))
            class_.delete_document(id)
            num_deleted += 1
          end
          index += 1
          progress.report(index, "Deleting stale documents")
        end
        start += limit
      end
      puts "\nDeleted #{num_deleted} documents"
    end

    ##
    # Reindexes all of the class' indexed documents. Multi-threaded indexing is
    # supported for potentially major performance gains, but care must be taken
    # not to overwhelm the Elasticsearch cluster.
    #
    # N.B.: Orphaned documents are not deleted; for that, use
    # {delete_orphaned_documents}.
    #
    # @param es_index [String] Index name. If omitted, the default index is
    #                          used.
    # @param num_threads [Integer]
    # @return [void]
    #
    def reindex_all(es_index = nil, num_threads = 1)
      mutex        = Mutex.new
      threads      = []
      record_count = count
      record_index = 0
      per_thread   = (record_count / num_threads.to_f).ceil
      progress     = Progress.new(record_count)

      num_threads.times do |thread_index|
        threads << Thread.new do
          ActiveRecord::Base.uncached do
            all.offset(thread_index * per_thread).
                limit(per_thread).
                find_each do |model|
              model.reindex(es_index)
              mutex.synchronize do
                progress.report(record_index,
                                "Indexing #{name.downcase.pluralize}")
                record_index += 1
              end
            end
          end
        end
      end
      threads.each(&:join)
      puts ""
    end

    ##
    # @return [AbstractFinder] Instance of one of the {AbstractFinder}
    #                          subclasses.
    #
    def search
      "#{name}Finder".constantize.new
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
    # @return [Hash] Indexable JSON representation of the instance. Does not
    #                need to include the model's ID.
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
