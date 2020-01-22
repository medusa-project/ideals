# frozen_string_literal: true

##
# See the documentation of {Indexed} for a detailed explanation of how indexing
# works.
#
class Unit < ApplicationRecord
  include Breadcrumb
  include Indexed

  class IndexFields
    CLASS         = ElasticsearchIndex::StandardFields::CLASS
    CREATED       = ElasticsearchIndex::StandardFields::CREATED
    ID            = ElasticsearchIndex::StandardFields::ID
    LAST_INDEXED  = ElasticsearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED = ElasticsearchIndex::StandardFields::LAST_MODIFIED
    PARENT        = 'i_parent_id'
    TITLE         = 't_title'
  end

  belongs_to :parent, class_name: "Unit", foreign_key: "parent_id", optional: true
  breadcrumbs parent: nil, label: :title
  scope :top, -> { where(parent_id: nil) }
  scope :bottom, -> { where(children.count == 0) }
  has_and_belongs_to_many :collections
  has_many :units, dependent: :restrict_with_exception
  has_many :roles, through: :administrators

  ##
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json
    doc = {}
    doc[IndexFields::CLASS]         = self.class.to_s
    doc[IndexFields::CREATED]       = self.created_at.utc.iso8601
    doc[IndexFields::LAST_INDEXED]  = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED] = self.updated_at.utc.iso8601
    doc[IndexFields::PARENT]        = self.parent&.id
    doc[IndexFields::TITLE]         = self.title
    doc
  end

  def label
    title
  end

  def relative_handle
    handle = Handle.find_by(resource_type_id: ResourceType::UNIT, resource_id: id)
    return nil unless handle

    handle.handle
  end

  def children
    Unit.where(parent_id: id)
  end

  def parents
    Unit.where(id: self.parent_id)
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
