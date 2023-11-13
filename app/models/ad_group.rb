# frozen_string_literal: true

##
# Encapsulates an AD group associated with a [UserGroup]. Users' membership
# in one of these groups may be checked to determine inclusion in the group.
#
# # Attributes
#
# * `created_at` Managed by ActiveRecord.
# * `name`       Group name. (This is also the last path component of a group
#                URN supplied in the OmniAuth hash.) This is not
#                controlled/unique.
# * `updated_at` Managed by ActiveRecord.
#
class AdGroup < ApplicationRecord

  belongs_to :user_group

  normalizes :name, with: -> (value) { value.squish }

  validates :name, presence: true

  def to_s
    name
  end

end
