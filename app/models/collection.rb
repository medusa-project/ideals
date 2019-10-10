class Collection < ApplicationRecord
  include Breadcrumb
  belongs_to :collection_group
  belongs_to :parent, class_name: 'CollectionGroup', foreign_key: 'collection_group_id'
  breadcrumbs parent: :collection_group, label: :title
  has_many :items, dependent: :restrict_with_exception
  has_and_belongs_to_many :managers, inverse_of: :collections
  accepts_nested_attributes_for :managers
  validates_uniqueness_of :title, scope: :collection_group

  def label
    title
  end

  def relative_handle
    handle = Handle.find_by(resource_type_id: Ideals::ResourceType::COLLECTION, resource_id: id)
    return nil unless handle
    handle.handle
  end

  def add_manager(manager)
    managers << manager
  end

  def remove_manager(manager)
    managers.delete(manager)
  end

end
