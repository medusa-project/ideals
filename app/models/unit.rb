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

  has_and_belongs_to_many :collections
  belongs_to :parent, class_name: "Unit", foreign_key: "parent_id", optional: true
  scope :top, -> { where(parent_id: nil) }
  scope :bottom, -> { where(children.count == 0) }
  has_many :roles, through: :administrators
  has_many :units, foreign_key: "parent_id", dependent: :restrict_with_exception

  breadcrumbs parent: :parent, label: :title

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

  def default_search
    nil
  end

end
