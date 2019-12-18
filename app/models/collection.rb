class Collection < ApplicationRecord
  include Breadcrumb
  belongs_to :unit
  belongs_to :parent, class_name: 'Unit', foreign_key: 'parent_unit_id'
  breadcrumbs parent: :unit, label: :title
  has_many :items, dependent: :restrict_with_exception
  validates_uniqueness_of :title, scope: :unit

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
    handle = Handle.find_by(resource_type_id: Ideals::ResourceType::COLLECTION, resource_id: id)
    return nil unless handle
    handle.handle
  end
end
