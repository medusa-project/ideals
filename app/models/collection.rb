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
class Collection < ApplicationRecord
  include Breadcrumb
  belongs_to :primary_unit, class_name: "Unit",
             foreign_key: "primary_unit_id", optional: true
  breadcrumbs parent: :primary_unit, label: :title
  has_and_belongs_to_many :items
  has_many :collection_unit_relationships
  has_one :primary_collection_unit_relationship, -> { where(primary: true) },
          class_name: "CollectionUnitRelationship"
  has_one :primary_unit, through: :primary_collection_unit_relationship,
          source: :unit
  has_many :units, through: :collection_unit_relationships
  has_many :roles, through: :managers

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
