# frozen_string_literal: true

class Unit < ApplicationRecord
  include Breadcrumb
  belongs_to :parent, class_name: "Unit", foreign_key: "parent_unit_id", optional: true
  breadcrumbs parent: nil, label: :title
  scope :top, -> { where(parent_unit_id: nil) }
  scope :bottom, -> { where(child_units.count == 0) }
  has_many :collections, dependent: :restrict_with_exception
  has_many :units, dependent: :restrict_with_exception

  def label
    title
  end

  def relative_handle
    handle = Handle.find_by(resource_type_id: Ideals::ResourceType::UNIT, resource_id: id)
    return nil unless handle

    handle.handle
  end

  def child_units
    Unit.where(parent_unit_id: id)
  end

  def parent_unit
    Unit.where(id: self.parent_unit_id)
  end

  def descendant_units
    self.child_units | self.child_units.map(&:descendant_units).flatten
  end

  def ancestor_units
    self.parent_unit | self.parent_unit.map(&:ancestor_units).flatten
  end

  def default_search
    nil
  end
end
