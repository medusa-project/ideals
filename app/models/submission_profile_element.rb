##
# Encapsulates an element in a {SubmissionProfile}. Essentially this is a
# glorified join model between {SubmissionProfile} and {RegisteredElement}.
#
# # Attributes
#
# * `created_at`            Managed by ActiveRecord.
# * `help_text`             Help text.
# * `index`                 Zero-based position within the owning
#                           {SubmissionProfile}.
# * `placeholder_text`      Text that is inserted into form inputs by default.
# * `registered_element_id` ID of the associated {RegisteredElement}. Foreign
#                           key.
# * `repeatable`            Whether multiple matching {AscribedElement}s can be
#                           associated with an entity.
# * `required`              Whether a matching {AscribedElement} must be
#                           associated with an entity.
# * `submission_profile_id` ID of the associated {SubmissionProfile}. Foreign
#                           key.
# * `updated_at`            Managed by ActiveRecord.
#
class SubmissionProfileElement < ApplicationRecord

  belongs_to :submission_profile, inverse_of: :elements, touch: true
  belongs_to :registered_element, inverse_of: :submission_profile_elements

  # index -- note that uniqueness is not validated here as we are going to
  # handle that in persistence callbacks instead.
  validates :index, numericality: { only_integer: true,
                                    greater_than_or_equal_to: 0 }
  validates_presence_of :index

  # registered_element_id
  validates_presence_of :registered_element_id
  validates_uniqueness_of :registered_element_id, scope: :submission_profile_id

  before_create :shift_element_indexes_before_create
  before_update :shift_element_indexes_before_update
  after_destroy :shift_element_indexes_after_destroy

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
  # Increments the indexes of all elements in the owning {SubmissionProfile}
  # that are greater than or equal to the index of this instance, in order to
  # make room for it.
  #
  def shift_element_indexes_before_create
    transaction do
      self.submission_profile.elements.where("index >= ?", self.index).each do |e|
        # update_column skips callbacks, which would cause this method to
        # be called recursively.
        e.update_column(:index, e.index + 1)
      end
    end
  end

  ##
  # Updates the indexes of all elements in the owning {SubmissionProfile} to
  # ensure that they are sequential.
  #
  def shift_element_indexes_before_update
    if self.index_changed? && self.submission_profile
      min       = [self.index_was, self.index].min
      max       = [self.index_was, self.index].max
      increased = (self.index_was < self.index)

      transaction do
        self.submission_profile.elements.
            where('id != ? AND index >= ? AND index <= ?', self.id, min, max).each do |e|
          if increased # shift the range down
            # update_column skips callbacks, which would cause this method to
            # be called recursively.
            e.update_column(:index, e.index - 1)
          else # shift it up
            e.update_column(:index, e.index + 1)
          end
        end
      end
    end
  end

  ##
  # Updates the indexes of all elements in the owning {SubmissionProfile} to
  # ensure that they are sequential and zero-based.
  #
  def shift_element_indexes_after_destroy
    if self.submission_profile && self.destroyed?
      transaction do
        self.submission_profile.elements.order(:index).each_with_index do |element, index|
          # update_column skips callbacks, which would cause this method to be
          # called recursively.
          element.update_column(:index, index) if element.index != index
        end
      end
    end
  end

end
