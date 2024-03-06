# frozen_string_literal: true

##
# University department associated with a {UserGroup} and a UIUC user.
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

  SAML_DEPARTMENT_CODE_ATTRIBUTE = "urn:oid:1.3.6.1.4.1.11483.1.122"

  belongs_to :user, optional: true
  belongs_to :user_group, optional: true

  normalizes :name, with: -> (value) { value.squish }

  ##
  # @param attrs [OneLogin::RubySaml::Attributes]
  # @return [Department]
  #
  def self.from_omniauth(attrs)
    name = attrs[SAML_DEPARTMENT_CODE_ATTRIBUTE]
    name = name.first if name.respond_to?(:each)
    name.present? ? Department.new(name: name) : nil
  end

  def to_s
    name
  end

end
