##
# Restricts [Item] access until an expiration date.
#
# # Attributes
#
# * `created_at`  Managed by ActiveRecord.
# * `download`    If true, downloads are restricted.
# * `expires_at`  Date/time at which the embargo expires.
# * `full_access` If true, all access to the item is restricted.
# * `item_id`     References the owning {Item}.
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

  scope :current, -> { where("expires_at > NOW()")}
  belongs_to :item
  has_and_belongs_to_many :user_groups, -> { order(:name) }

  validate :validate_expiration
  validate :validate_restrictions

  class IndexFields
    DOWNLOAD    = "b_download"
    EXPIRES_AT  = "d_expires_at"
    FULL_ACCESS = "b_full_access"
  end

  ##
  # @return [Hash]
  #
  def as_indexed_json
    {
      IndexFields::DOWNLOAD    => self.download,
      IndexFields::FULL_ACCESS => self.full_access,
      IndexFields::EXPIRES_AT  => self.expires_at.iso8601
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
    if expires_at < Time.now
      errors.add(:expires_at, "must be in the future")
    end
  end

  ##
  # Ensures that at least one restriction is set.
  #
  def validate_restrictions
    unless download || full_access
      errors.add(:base, "At least one restriction must be applied.")
    end
  end

end
