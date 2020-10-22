class LdapGroup < ApplicationRecord
  include Breadcrumb

  has_and_belongs_to_many :user_groups
  has_and_belongs_to_many :users

  # name uniqueness enforced by database constraints
  validates :name, presence: true

  def label
    name
  end

end
