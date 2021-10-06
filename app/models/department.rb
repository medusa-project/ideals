##
# University department associated with a {UserGroup}.
#
# # Attributes
#
# * `created_at` Managed by ActiveRecord.
# * `name`       Department name, which must match the name of the department
#                the university directory.
# * `updated_at` Managed by ActiveRecord.
#
class Department < ApplicationRecord

  belongs_to :user_group

end
