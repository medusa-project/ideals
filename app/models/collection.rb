class Collection < ApplicationRecord
  has_and_belongs_to_many :managers, inverse_of: :collections
  accepts_nested_attributes_for :managers
  validates_uniqueness_of :title

  def add_manager(manager)
    managers << manager
  end

  def remove_manager(manager)
    managers.delete(manager)
  end

end
