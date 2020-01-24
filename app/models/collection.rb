# frozen_string_literal: true

##
# A collection is a container for {Item}s.
#
# # Relationships
#
# Collections have a many-to-many relationship with {Item}s and {Unit}s. The
# relationship to {Unit}s is through the {CollectionUnitRelationship} model
# which enables designation of one of them as primary.
#
# # Indexing
#
# See the documentation of {Indexed} for a detailed explanation of how indexing
# works.
#
class Collection < ApplicationRecord
  include Breadcrumb
  include Indexed

  class IndexFields
    CLASS         = ElasticsearchIndex::StandardFields::CLASS
    CREATED       = ElasticsearchIndex::StandardFields::CREATED
    DESCRIPTION   = "t_description"
    ID            = ElasticsearchIndex::StandardFields::ID
    LAST_INDEXED  = ElasticsearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED = ElasticsearchIndex::StandardFields::LAST_MODIFIED
    PRIMARY_UNIT  = "i_primary_unit_id"
    TITLE         = "t_title"
    UNITS         = "i_units"
  end

  belongs_to :primary_unit, class_name: "Unit",
             foreign_key: "primary_unit_id", optional: true
  breadcrumbs parent: :primary_unit, label: :title
  has_many :collection_unit_relationships
  has_many :item_collection_relationships
  has_many :items, through: :item_collection_relationships
  has_one :primary_collection_unit_relationship, -> { where(primary: true) },
          class_name: "CollectionUnitRelationship"
  has_one :primary_unit, through: :primary_collection_unit_relationship,
          source: :unit
  has_many :units, through: :collection_unit_relationships
  has_many :roles, through: :managers

  ##
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json
    doc = {}
    doc[IndexFields::CLASS]         = self.class.to_s
    doc[IndexFields::CREATED]       = self.created_at.utc.iso8601
    doc[IndexFields::DESCRIPTION]   = self.description
    doc[IndexFields::LAST_INDEXED]  = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED] = self.updated_at.utc.iso8601
    doc[IndexFields::PRIMARY_UNIT]  = self.primary_unit&.id
    doc[IndexFields::TITLE]         = self.title
    doc[IndexFields::UNITS]         = self.unit_ids
    doc
  end

  def label
    title
  end

  def default_search
    Item.search do
      with :collection_id, id
      paginate(page: 1, per_page: 25)
    end
  end

  ##
  # Sets the primary unit, but does not remove the current primary unit from
  # {units}.
  #
  # @param unit [Unit] New primary unit.
  #
  def primary_unit=(unit)
    self.collection_unit_relationships.update_all(primary: false)
    self.collection_unit_relationships.build(unit: unit, primary: true).save!
  end

  def relative_handle
    handle = Handle.find_by(resource_type_id: ResourceType::COLLECTION, resource_id: id)
    return nil unless handle

    handle.handle
  end
end
