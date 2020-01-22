# frozen_string_literal: true

class Collection < ApplicationRecord
  include Breadcrumb
  belongs_to :unit
  belongs_to :primary_unit, class_name: "Unit", foreign_key: "primary_unit_id", optional: true
  breadcrumbs parent: :primary_unit, label: :title
  has_and_belongs_to_many :items
  has_and_belongs_to_many :units
  validates :title, uniqueness: {scope: :unit}
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

  def relative_handle
    handle = Handle.find_by(resource_type_id: ResourceType::COLLECTION, resource_id: id)
    return nil unless handle

    handle.handle
  end
end
