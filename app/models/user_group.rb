class UserGroup < ApplicationRecord
  include Breadcrumb

  has_and_belongs_to_many :users

  validates :name, presence: true
  validates_uniqueness_of :name, allow_blank: false

  def label
    name
  end

end
