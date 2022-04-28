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
  include Breadcrumb

  belongs_to :user_group

  validates :name, presence: true

  def breadcrumb_label
    name
  end

  def to_s
    name
  end

end
