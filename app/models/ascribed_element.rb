##
# Attachment of a [RegisteredElement] to a [Describable] resource--typically
# either an [Item] or a [Collection].
#
# N.B.: Because it is so common to access multiple elements ascribed to the
# same entity during a single request, it is usually very beneficial for
# performance to call `includes(:elements)` on an [ActiveRecord::Relation]
# before accessing the results.
#
# # Attributes
#
# * `collection_id`:         ID of the associated [Collection]. Set only if
#                            `item_id` is not set.
# * `created_at`:            Managed by ActiveRecord.
# * `item_id`:               ID of the associated [Item]. Set only if
#                            `collection_id` is not set.
# * `position`               Position relative to other [AscribedElement]s
#                            **with the same name** attached to the same
#                            resource. The counting starts at 1.
# * `registered_element_id`: ID of the associated [RegisteredElement].
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
  belongs_to :item, touch: !DspaceImporter.instance.running?

  validates :string, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 1 },
            allow_blank: false

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

end
