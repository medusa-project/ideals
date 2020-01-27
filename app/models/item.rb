# frozen_string_literal: true

##
# Encapsulates a unit of intellectual content.
#
# See the documentation of {Indexed} for a detailed explanation of how indexing
# works.
#
class Item < ApplicationRecord
  include Breadcrumb
  include Indexed

  ##
  # Contains constants for all "technical" indexed fields. Additional dynamic
  # metadata fields may also be present.
  #
  class IndexFields
    CLASS              = ElasticsearchIndex::StandardFields::CLASS
    COLLECTIONS        = "i_collection_ids"
    CREATED            = ElasticsearchIndex::StandardFields::CREATED
    ID                 = ElasticsearchIndex::StandardFields::ID
    LAST_INDEXED       = ElasticsearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED      = ElasticsearchIndex::StandardFields::LAST_MODIFIED
    PRIMARY_COLLECTION = "i_primary_collection_id"
    PRIMARY_UNIT       = "i_primary_unit_id"
  end

  has_many :bitstreams
  has_many :item_collection_relationships
  has_one :primary_item_collection_relationship, -> { where(primary: true) },
          class_name: "ItemCollectionRelationship"
  has_one :primary_collection, through: :primary_item_collection_relationship,
          source: :collection
  has_many :collections, through: :item_collection_relationships

  breadcrumbs parent: :primary_collection, label: :title

  ##
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json
    doc = {}
    doc[IndexFields::CLASS]              = self.class.to_s
    doc[IndexFields::COLLECTIONS]        = self.collection_ids
    doc[IndexFields::CREATED]            = self.created_at.utc.iso8601
    doc[IndexFields::LAST_INDEXED]       = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED]      = self.updated_at.utc.iso8601
    doc[IndexFields::PRIMARY_COLLECTION] = self.primary_collection&.id
    doc[IndexFields::PRIMARY_UNIT]       = self.primary_unit&.id
    doc
  end

  def label
    title
  end

  def default_search
    nil
  end

  ##
  # Sets the primary collection, but does not remove the current primary
  # collection from {collections}.
  #
  # @param collection [Collection] New primary collection.
  #
  def primary_collection=(collection)
    self.item_collection_relationships.update_all(primary: false)
    self.item_collection_relationships.build(collection: collection,
                                             primary: true).save!
  end

  ##
  # @return [Unit]
  #
  def primary_unit
    self.primary_collection&.primary_unit
  end

  def relative_handle
    handle = Handle.find_by(resource_type_id: ResourceType::ITEM, resource_id: id)
    return nil unless handle

    handle.handle
  end
end
