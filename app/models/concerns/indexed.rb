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
                              ElasticsearchIndex::StandardFields::CLASS => name
                          }
                      },
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
    # N.B.: Orphaned documents are not deleted; for that, use
    # {delete_orphaned_documents}.
    #
    # @param index [String] Index name. If omitted, the default index is used.
    # @return [void]
    #
    def reindex_all(index = nil)
      count_ = count
      start_time = Time.now
      ActiveRecord::Base.uncached do
        all.find_each.with_index do |model, i|
          model.reindex(index)
          StringUtils.print_progress(start_time, i, count_,
                                     "Indexing #{name.downcase.pluralize}")
        end
        puts ""
      end
    end

    ##
    # @return [AbstractFinder] Instance of one of the {AbstractFinder}
    #                          subclasses.
    #
    def search
      "#{name}Finder".constantize.new
    end
  end

  included do
    after_commit :reindex, on: [:create, :update]
    after_commit -> { delete_document(id) }, on: :destroy

    ##
    # @return [Hash] Indexable JSON representation of the instance. Does not
    #                need to include the model's ID.
    #
    def as_indexed_json
      raise 'Including classes must override as_indexed_json()'
    end

    ##
    # @param index [String] Index name. If omitted, the default index is used.
    # @return [void]
    #
    def reindex(index = nil)
      index ||= Configuration.instance.elasticsearch[:index]
      ElasticsearchClient.instance.index_document(index,
                                                  self.id,
                                                  self.as_indexed_json)
    end
  end

end
