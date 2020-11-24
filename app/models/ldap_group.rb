##
# Encapsulates an LDAP/AD group provided by a Shibboleth IdP.
#
# # Attributes
#
# * `created_at` Managed by ActiveRecord.
# * `updated_at` Managed by ActiveRecord.
# * `urn`        Group URN.
#
class LdapGroup < ApplicationRecord
  include Breadcrumb

  has_and_belongs_to_many :user_groups
  has_and_belongs_to_many :users

  # uniqueness enforced by database constraints
  validates :urn, presence: true

  def label
    short_name
  end

  ##
  # @return [String] Last path component of the URN.
  #
  def short_name
    urn.split(":").last.split(" ").map(&:capitalize).join(" ")
  end

  def to_s
    urn
  end

end
