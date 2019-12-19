# frozen_string_literal: true

class Unit < ApplicationRecord
  include Breadcrumb
  belongs_to :parent, class_name: "Unit", foreign_key: "parent_unit_id", optional: true
  breadcrumbs parent: nil, label: :title
  scope :top, -> { where(parent_unit_id: nil) }
  scope :bottom, -> { where(children.count == 0) }
  has_many :collections, dependent: :restrict_with_exception
  has_many :units, dependent: :restrict_with_exception
  has many :roles, through: :administrators

  def label
    title
  end

  def relative_handle
    handle = Handle.find_by(resource_type_id: Ideals::ResourceType::UNIT, resource_id: id)
    return nil unless handle

    handle.handle
  end

  def children
    Unit.where(parent_unit_id: id)
  end

  def parents
    Unit.where(id: self.parent_unit_id)
  end

  def descendants
    self.children | self.children.map(&:descendants).flatten
  end

  def ancestors
    self.parents | self.parents.map(&:ancestors).flatten
  end

  def default_search
    nil
  end
end
