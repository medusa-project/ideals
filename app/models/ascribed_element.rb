##
# Attachment of a {RegisteredElement} to a resource--either an {Item} or
# {Collection}.
#
class AscribedElement < ApplicationRecord
  belongs_to :registered_element
  belongs_to :collection, optional: true
  belongs_to :item, optional: true

  validates :string, presence: true

  validate :validate_ascription

  ##
  # @return [String]
  #
  def name
    registered_element.name
  end

  private

  ##
  # Ensures that the instance is attached to either an {Item} or a {Collection}
  # but not both.
  #
  def validate_ascription
    if item_id.blank? and collection_id.blank?
      errors.add(:base, "Element must be attached to a resource.")
    elsif item.id.present? and collection_id.present?
      errors.add(:base, "Element cannot be attached to multiple resources.")
    end
  end
end
