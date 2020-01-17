# frozen_string_literal: true

##
# Encapsulates a unit of intellectual content.
#
# # Indexing
#
# Items are searchable via ActiveRecord as well as via Elasticsearch. A low-
# level interface to Elasticsearch is provided by ElasticsearchClient, but
# in most cases, it's better to use the higher-level query interface provided
# by {ItemFinder}, which is easier to use, and takes public accessibility etc.
# into account.
#
# **IMPORTANT**: Instances are automatically indexed in Elasticsearch (see
# {as_indexed_json}) upon transaction commit. They are **not** indexed on
# save or delete. Whenever creating, updating, or deleting outside of a
# transaction, you must {reindex reindex} or {delete_document delete} the
# document manually.
#
class Item < ApplicationRecord
  include Breadcrumb

  ##
  # Contains constants for all "technical" indexed fields. Additional dynamic
  # metadata fields may also be present.
  #
  class IndexFields
    CLASS         = ElasticsearchIndex::StandardFields::CLASS
    COLLECTION    = 'k_collection'
    CREATED       = 'd_created'
    ID            = ElasticsearchIndex::StandardFields::ID
    LAST_INDEXED  = ElasticsearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED = ElasticsearchIndex::StandardFields::LAST_MODIFIED
    PARENT        = 'i_parent'
  end

  belongs_to :collection, optional: true
  belongs_to :parent, class_name: "Unit", foreign_key: "collection_id",
             optional: true
  breadcrumbs parent: :collection, label: :title

  after_commit :reindex, on: [:create, :update]
  after_commit -> { self.class.delete_document(self.id) }, on: :destroy

  ##
  # Normally this method should not be used except to delete "orphaned"
  # documents with no database counterpart. See the class documentation for
  # information about correct document deletion.
  #
  def self.delete_document(id)
    query = {
        query: {
            bool: {
                filter: [
                    {
                        term: {
                            Item::IndexFields::ID => id
                        }
                    }
                ]
            }
        }
    }
    ElasticsearchClient.instance.delete_by_query(JSON.generate(query))
  end

  ##
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json
    doc = {}
    doc[IndexFields::CLASS]         = self.class.to_s
    doc[IndexFields::COLLECTION]    = self.collection&.id
    doc[IndexFields::CREATED]       = self.created_at.utc.iso8601
    doc[IndexFields::LAST_INDEXED]  = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED] = self.updated_at.utc.iso8601
    doc[IndexFields::PARENT]        = self.parent&.id
    doc
  end

  def label
    title
  end

  def default_search
    nil
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

  def relative_handle
    handle = Handle.find_by(resource_type_id: ResourceType::ITEM, resource_id: id)
    return nil unless handle

    handle.handle
  end
end
