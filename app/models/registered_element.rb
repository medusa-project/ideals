class RegisteredElement < ApplicationRecord

  validates_format_of :name, with: /\A[A-Za-z0-9_\-:]+\z/, allow_blank: false
  validates_uniqueness_of :name

  def to_param
    name
  end

end
