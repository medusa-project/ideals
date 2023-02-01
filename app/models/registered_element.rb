##
# An element available for use in the application.
#
# Instances comprise a flat list. {AscribedElement} attaches them to entities
# and {MetadataProfileElement} attaches them to {MetadataProfile}s.
#
# Most elements are scoped to an {Institution}, except for a few global
# elements that are used by the {MetadataProfile#global global metadata profile}
# in cross-institution contexts. Element names must be unique within the scope.
#
# # System-Required Elements
#
# The system requires certain elements to be present, such as a title element,
# an author element, etc. These are defined by properties of {Institution} like
# {Institution#title_element_mapping}, etc.
#
# # Attributes
#
# * `created_at`       Managed by ActiveRecord.
# * `highwire_mapping` Name of an equivalent element in the Highwire Press
#                      meta tag vocabulary.
# * `input_type`       One of the {InputType} constant values.
# * `label`            Element label. Often overrides {name} for end-user
#                      display.
# * `name`             Element name. Must be unique within an institution.
# * `updated_at`       Managed by ActiveRecord.
# * `uri`              Linked Data URI. Must be unique within an institution.
# * `vocabulary_id`    Foreign key tp {Vocabulary}.
#
class RegisteredElement < ApplicationRecord

  class InputType
    DATE       = "date"
    PERSON     = "person"
    TEXT_AREA  = "text_area"
    TEXT_FIELD = "text_field"

    ##
    # @return [Enumerable<String>] All constant values.
    #
    def self.all
      self.constants.map{ |c| self.const_get(c) }
    end
  end

  DATE_FIELD_PREFIX     = "d"
  KEYWORD_FIELD_SUFFIX  = ".keyword"
  SORTABLE_FIELD_SUFFIX = ".sort"
  TEXT_FIELD_PREFIX     = "t"

  belongs_to :institution
  belongs_to :vocabulary, optional: true

  has_many :metadata_profile_elements, inverse_of: :registered_element
  has_many :submission_profile_elements, inverse_of: :registered_element

  has_and_belongs_to_many :index_pages

  # input_type (we allow blank because the database will assign a default value)
  validates :input_type, inclusion: { in: InputType.all }, allow_blank: true

  # label
  validates_presence_of :label

  # name
  validates_format_of :name, with: /\A[A-Za-z0-9_\-:]+\z/, allow_blank: false

  before_save :assign_default_input_type

  ##
  # @param name [String] Element name.
  # @return [String] Name of the corresponding sortable field in an indexed
  #                  document.
  #
  def self.sortable_field(name)
    [TEXT_FIELD_PREFIX,
     "element",
     name.gsub(OpenSearchClient::RESERVED_CHARACTERS, "_")].join("_") +
      SORTABLE_FIELD_SUFFIX
  end

  ##
  # @return [String] Name of the keyword field in which the element is stored
  #                  in indexed documents.
  #
  def indexed_keyword_field
    [indexed_field, KEYWORD_FIELD_SUFFIX].join
  end

  ##
  # @return [String] Name of the field in which the element is stored in
  #                  indexed documents.
  #
  def indexed_field
    # N.B.: changing this probably requires changing the index schema and/or
    # reindexing.
    [(self.input_type == InputType::DATE) ? DATE_FIELD_PREFIX : TEXT_FIELD_PREFIX,
     "element",
     name.gsub(OpenSearchClient::RESERVED_CHARACTERS, "_")].join("_")
  end

  ##
  # @return [String] Name of the sort field in which the element is stored in
  #                  indexed documents.
  #
  def indexed_sort_field
    (self.input_type == InputType::DATE) ?
      indexed_field : [indexed_field, SORTABLE_FIELD_SUFFIX].join
  end

  ##
  # @return [String] Name of the keyword field in which the element is stored
  #                  in indexed documents.
  #
  def indexed_text_field
    [TEXT_FIELD_PREFIX,
     "element",
     name.gsub(OpenSearchClient::RESERVED_CHARACTERS, "_")].join("_")
  end

  def to_param
    name
  end


  private

  def assign_default_input_type
    self.input_type ||= InputType::TEXT_FIELD
  end

end
