##
# An element available for use in the application.
#
# Instances comprise a simple list. {AscribedElement} attaches them to entities
# and {MetadataProfileElement} attaches them to {MetadataProfile}s.
#
class RegisteredElement < ApplicationRecord

  METADATA_FIELD_PREFIX = "metadata_"
  KEYWORD_FIELD_SUFFIX  = ".keyword"
  SORTABLE_FIELD_SUFFIX = ".sort"

  has_many :metadata_profile_elements, inverse_of: :registered_element

  validates_format_of :name, with: /\A[A-Za-z0-9_\-:]+\z/, allow_blank: false
  validates_uniqueness_of :name

  ##
  # @param name [String] Element name.
  # @return [String] Name of the corresponding sortable field in an indexed
  #                  document.
  #
  def self.sortable_field(name)
    [METADATA_FIELD_PREFIX,
     name.gsub(ElasticsearchClient::RESERVED_CHARACTERS, "_"),
     SORTABLE_FIELD_SUFFIX].join
  end

  ##
  # @return [String] Name of the keyword field in which the element is stored
  #                  in indexed documents.
  #
  def indexed_keyword_field
    [indexed_name, KEYWORD_FIELD_SUFFIX].join
  end

  ##
  # @return [String] Name of the field in which the element is stored in
  #                  indexed documents.
  #
  def indexed_name # TODO: rename to indexed_field
    # N.B.: changing this probably requires changing the index schema and/or
    # reindexing.
    [METADATA_FIELD_PREFIX,
     name.gsub(ElasticsearchClient::RESERVED_CHARACTERS, "_")].join
  end

  ##
  # @return [String] Name of the sort field in which the element is stored in
  #                  indexed documents.
  #
  def indexed_sort_field
    [indexed_name, SORTABLE_FIELD_SUFFIX].join
  end

  def to_param
    name
  end

end
