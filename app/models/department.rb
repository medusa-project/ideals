##
# University department associated with a {UserGroup} and a {ShibbolethUser}.
#
# This table is not normalized--multiple same-named departments may exist,
# associated with different entities, with {name} being used for comparison.
#
# # Attributes
#
# * `created_at` Managed by ActiveRecord.
# * `name`       Department name, which must match the name of the department
#                the university directory.
# * `updated_at` Managed by ActiveRecord.
#
class Department < ApplicationRecord

  belongs_to :user, optional: true
  belongs_to :user_group, optional: true

end