##
# An element available for use in the application.
#
# Instances comprise a simple list. {AscribedElement} attaches them to entities
# and {MetadataProfileElement} attaches them to {MetadataProfile}s.
#
# # Attributes
#
# * `created_at`       Managed by ActiveRecord.
# * `highwire_mapping` Name of an equivalent element in the Highwire Press
#                      meta tag vocabulary.
# * `input_type`       One of the [InputType] constant values.
# * `label`            Element label. Often overrides {name} for end-user
#                      display.
# * `name`             Element name. Must be unique within an institution.
# * `updated_at`       Managed by ActiveRecord.
# * `uri`              Linked Data URI. Must be unique within an institution.
# * `vocabulary_key`   One of the vocabulary key constant values in
#                      [Vocabulary].
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

  METADATA_FIELD_PREFIX = "metadata_"
  KEYWORD_FIELD_SUFFIX  = ".keyword"
  SORTABLE_FIELD_SUFFIX = ".sort"

  belongs_to :institution

  has_many :metadata_profile_elements, inverse_of: :registered_element
  has_many :submission_profile_elements, inverse_of: :registered_element

  # input_type
  validates :input_type, inclusion: { in: InputType.all }, allow_blank: true

  # label
  validates_presence_of :label

  # name
  validates_format_of :name, with: /\A[A-Za-z0-9_\-:]+\z/, allow_blank: false

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
    [indexed_field, KEYWORD_FIELD_SUFFIX].join
  end

  ##
  # @return [String] Name of the field in which the element is stored in
  #                  indexed documents.
  #
  def indexed_field
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
    [indexed_field, SORTABLE_FIELD_SUFFIX].join
  end

  def to_param
    name
  end

  ##
  # @return [Vocabulary] Instance corresponding to {vocabulary_key}, if set;
  #                      otherwise `nil`.
  #
  def vocabulary
    self.vocabulary_key.present? ?
      Vocabulary.with_key(self.vocabulary_key) : nil
  end

end
