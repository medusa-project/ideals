##
# An element available for use in the application.
#
# Instances comprise a simple list. {AscribedElement} attaches them to entities
# and {MetadataProfileElement} attaches them to {MetadataProfile}s.
#
# # System-Required Elements
#
# Some elements are required to be present for various functionality to work.
# These are defined in {SYSTEM_REQUIRED_ELEMENTS}.
#
# * `dc:creator`         Stores item authors.
# * `dc:date:issued`
# * `dc:date:submitted`  Automatically created upon submission of an item.
# * `dc:title`           Stores item titles.
# * `dcterms:available`  Automatically created upon approval of an item (which
#                        may be the same as the submission time).
# * `dcterms:identifier` Stores item handles.
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

  DATE_FIELD_PREFIX        = "d"
  KEYWORD_FIELD_SUFFIX     = ".keyword"
  SYSTEM_REQUIRED_ELEMENTS = %w(dc:creator dc:date:issued dc:date:submitted
                                dc:title dcterms:available dcterms:identifier)
  SORTABLE_FIELD_SUFFIX    = ".sort"
  TEXT_FIELD_PREFIX        = "t"

  belongs_to :institution
  belongs_to :vocabulary, optional: true

  has_many :metadata_profile_elements, inverse_of: :registered_element
  has_many :submission_profile_elements, inverse_of: :registered_element

  # input_type
  validates :input_type, inclusion: { in: InputType.all }, allow_blank: true

  # label
  validates_presence_of :label

  # name
  validates_format_of :name, with: /\A[A-Za-z0-9_\-:]+\z/, allow_blank: false

  before_save :restrict_changes_to_required_elements
  before_destroy :restrict_changes_to_required_elements

  ##
  # @param name [String] Element name.
  # @return [String] Name of the corresponding sortable field in an indexed
  #                  document.
  #
  def self.sortable_field(name)
    [TEXT_FIELD_PREFIX,
     "element",
     name.gsub(ElasticsearchClient::RESERVED_CHARACTERS, "_")].join("_") +
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
     name.gsub(ElasticsearchClient::RESERVED_CHARACTERS, "_")].join("_")
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
     name.gsub(ElasticsearchClient::RESERVED_CHARACTERS, "_")].join("_")
  end

  ##
  # @return [Boolean] Whether the element is required by the system. Such
  #                   elements should be unmodifiable.
  #
  def required?
    SYSTEM_REQUIRED_ELEMENTS.include?(self.name)
  end

  def to_param
    name
  end


  private

  def restrict_changes_to_required_elements
    if SYSTEM_REQUIRED_ELEMENTS.include?(self.name_was)
      errors.add(:base, "System-required elements cannot be changed")
      throw :abort
    end
  end

end
