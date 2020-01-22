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
    CREATED            = "d_created"
    ID                 = ElasticsearchIndex::StandardFields::ID
    LAST_INDEXED       = ElasticsearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED      = ElasticsearchIndex::StandardFields::LAST_MODIFIED
    PARENT             = "i_parent_id"
    PRIMARY_COLLECTION = "i_primary_collection_id"
  end

  has_and_belongs_to_many :collections
  belongs_to :primary_collection, class_name: 'Collection', optional: true
  belongs_to :parent, class_name: "Unit", foreign_key: "collection_id",
             optional: true
  breadcrumbs parent: :collection, label: :title

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
    doc[IndexFields::PARENT]             = self.parent&.id
    doc[IndexFields::PRIMARY_COLLECTION] = self.primary_collection&.id
    doc
  end

  def label
    title
  end

  def default_search
    nil
  end

  def relative_handle
    handle = Handle.find_by(resource_type_id: ResourceType::ITEM, resource_id: id)
    return nil unless handle

    handle.handle
  end
end
