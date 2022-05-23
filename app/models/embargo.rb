##
# Restricts [Item] access either perpetually or until a certain date,
# optionally exempting one or more [UserGroup]s.
#
# # Attributes
#
# * `created_at`  Managed by ActiveRecord.
# * `expires_at`  Date/time at which the embargo expires. For embargoes that
#                 never expire, {perpetual} is `true` and the value of this
#                 attribute is irrelevant.
# * `kind`        Value of one of the [Import::Kind] constants.
# * `item_id`     References the owning [Item].
# * `perpetual`   Whether the embargo ever expires. If `true`, the embargo
#                 never expires and the value of {expires_at} is irrelevant.
# * `reason`      Reason for the embargo.
# * `updated_at`  Managed by ActiveRecord.
#
# # Relationships
#
# * `item`        The owning [Item].
# * `user_groups` Zero or more [UserGroup]s that are exempt from the embargo.
#
class Embargo < ApplicationRecord

  include Auditable

  scope :all_access, -> { where(kind: Kind::ALL_ACCESS) }
  scope :current, -> { where("perpetual = true OR expires_at > NOW()")}
  belongs_to :item
  has_and_belongs_to_many :user_groups, -> { order(:name) }

  validates_inclusion_of :kind, in: -> (value) { Kind.all }

  validate :validate_expiration

  class IndexFields
    EXPIRES_AT  = "d_expires_at"
    KIND        = "i_kind"
  end

  class Kind
    # All access to the item via any means is restricted.
    ALL_ACCESS = 0
    # The item's bitstreams cannot be accessed.
    DOWNLOAD   = 1

    ##
    # @return [Enumerable<Integer>]
    #
    def self.all
      Kind.constants.map { |c| Kind.const_get(c) }
    end
  end

  def as_change_hash
    hash         = super
    hash['kind'] = Kind::constants.find{ |c| Kind.const_get(c) == self.kind }.to_s
    hash
  end

  ##
  # @return [Hash]
  #
  def as_indexed_json
    expires_at = self.expires_at
    expires_at = Time.now + 1000.years if self.perpetual || !expires_at
    {
      IndexFields::EXPIRES_AT => expires_at.iso8601,
      IndexFields::KIND       => self.kind
    }
  end

  ##
  # @param user [User]
  # @return [Boolean] Whether the given user is exempt from the embargo.
  #
  def exempt?(user)
    self.user_groups.each do |group|
      return true if group.includes?(user)
    end
    false
  end


  private

  ##
  # Ensures that {expires_at} is not in the past.
  #
  def validate_expiration
    if !perpetual && expires_at && expires_at < Time.now
      errors.add(:expires_at, "must be in the future")
    end
  end

end
