class RegisteredElement < ApplicationRecord

  METADATA_FIELD_PREFIX = "metadata_"
  SORTABLE_FIELD_SUFFIX = ".sort"

  validates_format_of :name, with: /\A[A-Za-z0-9_\-:]+\z/, allow_blank: false
  validates_uniqueness_of :name

  ##
  # @param name [String] Element name.
  # @return [String] Name of the corresponding sortable field in an indexed
  #                  document.
  #
  def self.sortable_field(name)
    [METADATA_FIELD_PREFIX, name, SORTABLE_FIELD_SUFFIX].join
  end

  ##
  # @return [String] Name of the field in which the element is stored in
  #                  indexed documents.
  #
  def indexed_name
    # N.B.: changing this requires changing the index schema.
    [METADATA_FIELD_PREFIX, name].join
  end

  def to_param
    name
  end

end
