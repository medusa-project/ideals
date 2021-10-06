##
# University affiliation associated with a {UserGroup}.
#
# # Attributes
#
# * `created_at` Managed by ActiveRecord.
# * `name`       Name of the affiliation.
# * `updated_at` Managed by ActiveRecord.
#
class Affiliation < ApplicationRecord

  has_and_belongs_to_many :user_groups

end
