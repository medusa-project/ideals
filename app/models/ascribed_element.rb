##
# Attachment of a {RegisteredElement} to a resource--either an {Item} or
# {Collection}.
#
# # Attributes
#
# * `collection_id`:         ID of the associated {Collection}. Set only if
#                            `item_id` is not set.
# * `created_at`:            Managed by ActiveRecord.
# * `item_id`:               ID of the associated {Item}. Set only if
#                            `collection_id` is not set.
# * `registered_element_id`: ID of the associated {RegisteredElement}.
# * `string`:                String value. Note that this may contain a date,
#                            which, when received from the submission form, is
#                            in `Month DD, YYYY` format.
# * `updated_at`:            Managed by ActiveRecord.
# * `uri`:                   Linked Data URI value.
#
class AscribedElement < ApplicationRecord

  belongs_to :registered_element
  # N.B.: "Touching" ensures that the owning resource is updated (its
  # `updated_at` column is updated and it is reindexed) when the instance is
  # updated. Normally, this is desired. However, it happens to make bulk-
  # importing metadata excruciatingly slow, so it is disabled during imports.
  belongs_to :collection, optional: true, touch: !IdealsImporter.instance.running?
  belongs_to :item, optional: true, touch: !IdealsImporter.instance.running?

  validates :string, presence: true
  validate :validate_ascription

  ##
  # @return [Date] Instance corresponding to the string value if it is
  #                recognized by {Date#parse}; otherwise `nil`.
  #
  def date
    self.string.present? ? Date.parse(self.string) : nil rescue nil
  end

  ##
  # @return [String] Label of the associated {RegisteredElement}.
  #
  def label
    registered_element&.label
  end

  ##
  # @return [String] Name of the associated {RegisteredElement}.
  #
  def name
    registered_element&.name
  end

  ##
  # @return [Hash<Symbol,String>,nil] Hash with `:family_name` and `:given_name`
  #                                   keys, or `nil` if {string} does not
  #                                   appear to contain a person name.
  #
  def person_name
    parts = self.string&.split(",") || []
    if parts.length >= 2
      return {
        family_name: parts[0].strip,
        given_name:  parts[1..].join(",").strip
      }
    end
    nil
  end


  private

  ##
  # Ensures that the instance is attached to either an {Item} or a {Collection}
  # but not both.
  #
  def validate_ascription
    if item_id.blank? and collection_id.blank?
      errors.add(:base, "Element must be attached to a resource.")
    elsif item_id.present? and collection_id.present?
      errors.add(:base, "Element cannot be attached to multiple resources.")
    end
  end
end
