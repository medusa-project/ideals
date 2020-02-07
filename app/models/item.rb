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
  has_and_belongs_to_many :collections
  has_many :elements, class_name: "AscribedElement"
  belongs_to :primary_collection, class_name: "Collection",
             foreign_key: "primary_collection_id", optional: true

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
    doc[IndexFields::PRIMARY_COLLECTION] = self.primary_collection_id
    doc[IndexFields::PRIMARY_UNIT]       = self.primary_unit&.id

    # Index ascribed metadata elements into dynamic fields.
    self.elements.each do |element|
      field = element.registered_element.indexed_name
      unless doc[field]&.respond_to?(:each)
        doc[field] = []
      end
      doc[field] << element.string[0..ElasticsearchClient::MAX_KEYWORD_FIELD_LENGTH]
    end

    doc
  end

  def label
    title
  end

  ##
  # @return [Unit]
  #
  def primary_unit
    self.primary_collection&.primary_unit
  end

end
