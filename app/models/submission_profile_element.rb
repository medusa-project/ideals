##
# Encapsulates an element in a [SubmissionProfile]. Essentially this is a
# glorified join model between [SubmissionProfile] and [RegisteredElement].
#
# # Attributes
#
# * `created_at`            Managed by ActiveRecord.
# * `help_text`             Help text.
# * `placeholder_text`      Text that is inserted into form inputs by default.
# * `position`              Zero-based position within the owning
#                           [SubmissionProfile].
# * `registered_element_id` ID of the associated [RegisteredElement]. Foreign
#                           key.
# * `repeatable`            Whether multiple matching [AscribedElement]s can be
#                           associated with an entity.
# * `required`              Whether a matching [AscribedElement] must be
#                           associated with an entity.
# * `submission_profile_id` ID of the associated [SubmissionProfile]. Foreign
#                           key.
# * `updated_at`            Managed by ActiveRecord.
#
class SubmissionProfileElement < ApplicationRecord

  belongs_to :submission_profile, inverse_of: :elements, touch: true
  belongs_to :registered_element, inverse_of: :submission_profile_elements

  # Note that uniqueness is not validated here as we are going to
  # handle that in persistence callbacks instead.
  validates :position, numericality: { only_integer: true,
                                       greater_than_or_equal_to: 0 }
  validates_presence_of :position

  # registered_element_id
  validates_presence_of :registered_element_id
  validates_uniqueness_of :registered_element_id, scope: :submission_profile_id

  validate :registered_element_and_profile_are_of_same_institution

  before_create :shift_element_positions_before_create
  before_update :shift_element_positions_before_update
  after_destroy :shift_element_positions_after_destroy

  ##
  # @return [String] The `label` property of the associated
  #                  {RegisteredElement}.
  #
  def label
    self.registered_element&.label
  end

  ##
  # @return [String] The `name` property of the associated {RegisteredElement}.
  #
  def name
    self.registered_element&.name
  end


  private

  ##
  # Increments the positions of all elements in the owning [SubmissionProfile]
  # that are greater than or equal to the position of this instance, in order
  # to make room for it.
  #
  def shift_element_positions_before_create
    transaction do
      self.submission_profile.elements.where("position >= ?", self.position).each do |e|
        # update_column skips callbacks, which would cause this method to
        # be called recursively.
        e.update_column(:position, e.position + 1)
      end
    end
  end

  ##
  # Updates the positions of all elements in the owning [SubmissionProfile] to
  # ensure that they are sequential.
  #
  def shift_element_positions_before_update
    if self.position_changed? && self.submission_profile
      min       = [self.position_was, self.position].min
      max       = [self.position_was, self.position].max
      increased = (self.position_was < self.position)

      transaction do
        self.submission_profile.elements.
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
  # Updates the positions of all elements in the owning [SubmissionProfile] to
  # ensure that they are sequential and zero-based.
  #
  def shift_element_positions_after_destroy
    if self.submission_profile && self.destroyed?
      transaction do
        self.submission_profile.elements.order(:position).each_with_index do |element, position|
          # update_column skips callbacks, which would cause this method to be
          # called recursively.
          element.update_column(:position, position) if element.position != position
        end
      end
    end
  end

  def registered_element_and_profile_are_of_same_institution
    profile = self.submission_profile&.institution
    reg_e   = self.registered_element
    if profile && reg_e && profile.id != reg_e.institution_id
      errors.add(:base, "Registered element and owning submission profile must "\
                        "be of the same institution")
      throw(:abort)
    end
  end

end
