##
# Encapsulates an element in a [MetadataProfile]. Essentially this is a
# glorified join model between [MetadataProfile] and [RegisteredElement].
#
# # Attributes
#
# * `created_at`            Managed by ActiveRecord.
# * `faceted`               Whether the element is used to provide facets in
#                           results views.
# * `metadata_profile_id`   ID of the associated metadata profile. Foreign key.
# * `position`              Zero-based position relative to other elements in
#                           the owning [MetadataProfile].
# * `registered_element_id` ID of the associated [RegisteredElement]. Foreign
#                           key.
# * `relevance_weight`      Weight of the element when computing a result
#                           relevance score. These are OpenSearch weights
#                           with a default and minimum of 1 and a maximum of
#                           10.
# * `searchable`            Whether users can search on the element.
# * `sortable`              Whether results can be sorted on the element.
# * `updated_at`            Managed by ActiveRecord.
# * `visible`               Whether the element is visible to users.
#
class MetadataProfileElement < ApplicationRecord

  MIN_RELEVANCE_WEIGHT     = 1
  MAX_RELEVANCE_WEIGHT     = 10
  # This should be synchronized with the default values of the
  # `metadata_profile_elements.relevance_weight` and
  # `metadata_profiles.full_text_relevance_weight` database columns.
  DEFAULT_RELEVANCE_WEIGHT = 5

  belongs_to :metadata_profile, inverse_of: :elements, touch: true
  belongs_to :registered_element, inverse_of: :metadata_profile_elements

  # Note that uniqueness is not validated here as we are going to handle that
  # in persistence callbacks instead.
  validates :position, numericality: { only_integer: true,
                                       greater_than_or_equal_to: 0 }
  validates_presence_of :position

  validates_presence_of :registered_element_id
  validates_uniqueness_of :registered_element_id, scope: :metadata_profile_id

  validates :relevance_weight, numericality: { only_integer: true,
                                               greater_than_or_equal_to: MIN_RELEVANCE_WEIGHT,
                                               less_than_or_equal_to: MAX_RELEVANCE_WEIGHT }

  validate :registered_element_and_profile_are_of_same_institution

  before_create :shift_element_positions_before_create
  before_update :shift_element_positions_before_update
  after_destroy :shift_element_positions_after_destroy

  ##
  # Alias of {RegisteredElement#indexed_field}.
  #
  def indexed_field
    self.registered_element.indexed_field
  end

  ##
  # Alias of {RegisteredElement#indexed_keyword_field}.
  #
  def indexed_keyword_field
    self.registered_element.indexed_keyword_field
  end

  ##
  # Alias of {RegisteredElement#indexed_sort_field}.
  #
  def indexed_sort_field
    self.registered_element.indexed_sort_field
  end

  ##
  # @return [String] Label of the associated {RegisteredElement}.
  #
  def label
    self.registered_element.label
  end

  ##
  # @return [String] Name of the associated {RegisteredElement}.
  #
  def name
    self.registered_element.name
  end


  private

  ##
  # Increments the positions of all elements in the owning [MetadataProfile]
  # that are greater than or equal to the position of this instance, in order
  # to make room for it.
  #
  def shift_element_positions_before_create
    transaction do
      self.metadata_profile.elements.where("position >= ?", self.position).each do |e|
        # update_column skips callbacks, which would cause this method to be
        # called recursively.
        e.update_column(:position, e.position + 1)
      end
    end
  end

  ##
  # Updates the positions of all elements in the owning [MetadataProfile] to
  # ensure that they are sequential.
  #
  def shift_element_positions_before_update
    if self.position_changed? && self.metadata_profile
      min       = [self.position_was, self.position].min
      max       = [self.position_was, self.position].max
      increased = (self.position_was < self.position)

      transaction do
        self.metadata_profile.elements.
            where('id != ? AND position >= ? AND position <= ?', self.id, min, max).each do |e|
          if increased # shift the range down
            # update_column skips callbacks, which would cause this method to
            # be called recursively.
            e.update_column(:position, e.position - 1)
          else # shift it up
            e.update_column(:position, e.position + 1)
          end
        end
      end
    end
  end

  ##
  # Updates the positions of all elements in the owning [MetadataProfile] to
  # ensure that they are sequential and zero-based.
  #
  def shift_element_positions_after_destroy
    if self.metadata_profile && self.destroyed?
      transaction do
        self.metadata_profile.elements.order(:position).each_with_index do |element, position|
          # update_column skips callbacks, which would cause this method to be
          # called recursively.
          element.update_column(:position, position) if element.position != position
        end
      end
    end
  end

  def registered_element_and_profile_are_of_same_institution
    profile = self.metadata_profile&.institution
    reg_e   = self.registered_element
    if profile && reg_e && profile.id != reg_e.institution_id
      errors.add(:base, "Registered element and owning metadata profile must "\
                        "be of the same institution")
      throw(:abort)
    end
  end

end
