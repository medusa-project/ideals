##
# Restricts {Item} access until an expiration date.
#
# # Attributes
#
# * `created_at`  Managed by ActiveRecord.
# * `download`    If true, downloads are restricted.
# * `expires_at`  Date/time at which the embargo expires.
# * `full_access` If true, all access to the item is restricted.
# * `item_id`     References the owning {Item}.
# * `updated_at`  Managed by ActiveRecord.
#
class Embargo < ApplicationRecord

  scope :current, -> { where("expires_at > NOW()")}
  belongs_to :item

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
      IndexFields::EXPIRES_AT  => self.expires_at.utc.iso8601
    }
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
