# frozen_string_literal: true

##
# University department associated with a {UserGroup} and a
# {#User::AuthType::SHIBBOLETH} user.
#
# This table is not normalized--multiple same-named departments may exist,
# associated with different entities, with {name} being used for comparison.
#
# # Attributes
#
# * `created_at` Managed by ActiveRecord.
# * `name`       Department name, which must match the name of the department
#                in the UIUC directory.
# * `updated_at` Managed by ActiveRecord.
#
class Department < ApplicationRecord

  belongs_to :user, optional: true
  belongs_to :user_group, optional: true

  normalizes :name, with: -> (value) { value.squish }

end
