class RegisteredElement < ApplicationRecord

  validates_format_of :name, with: /\A[A-Za-z0-9_\-:]+\z/, allow_blank: false
  validates_uniqueness_of :name

  ##
  # @return [String] Name of the field in which the element is stored in
  #                  indexed documents.
  #
  def indexed_name
    # N.B.: changing this requires changing the index schema.
    "metadata_#{name}"
  end

  def to_param
    name
  end

end
