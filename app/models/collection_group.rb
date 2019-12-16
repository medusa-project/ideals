class CollectionGroup < ApplicationRecord
  include Breadcrumb
  belongs_to :parent, class_name: 'CollectionGroup', foreign_key: 'parent_group_id', optional: true
  breadcrumbs parent: nil, label: :title
  scope :top, -> { where(parent_group_id: nil) }
  scope :bottom, -> { where(child_groups.count == 0) }
  has_many :collections, dependent: :restrict_with_exception
  has_many :collection_groups, dependent: :restrict_with_exception

  def label
    title
  end

  def relative_handle
    handle = Handle.find_by(resource_type_id: Ideals::ResourceType::COLLECTION_GROUP, resource_id: id)
    return nil unless handle

    handle.handle
  end

  def child_groups
    CollectionGroup.where(parent_group_id: id)
  end

  def descendant_groups
    raise("not yet implemented")
  end

  def ancestor_groups
    raise("not yet implemented")
  end

  def default_search
    nil
  end

end
