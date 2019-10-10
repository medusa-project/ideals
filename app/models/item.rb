class Item < ApplicationRecord
  include Breadcrumb
  belongs_to :collection
  belongs_to :parent, class_name: 'CollectionGroup', foreign_key: 'collection_id'
  breadcrumbs parent: :collection, label: :title

  searchable do
    text :title
    integer :collection_id
  end

  def label
    title
  end

  def relative_handle
    handle = Handle.find_by(resource_type_id: Ideals::ResourceType::ITEM, resource_id: id)
    return nil unless handle
    handle.handle
  end

end
