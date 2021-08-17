##
# Aggregation of {LocalUser}s, {LdapGroup}s, and {Host}s for the purpose of
# performing group-based authorization.
#
# # Attributes
#
# * `created_at` Managed by ActiveRecord.
# * `key`        Short unique identifying key.
# * `name`       Arbitrary but unique group name.
# * `updated_at` Managed by ActiveRecord.
#
class UserGroup < ApplicationRecord
  include Breadcrumb

  has_many :administrator_groups
  has_many :bitstream_authorizations
  has_many :hosts
  has_many :manager_groups
  has_many :submitter_groups

  has_and_belongs_to_many :ldap_groups
  # LocalUsers only!
  has_and_belongs_to_many :users

  # name uniqueness enforced by database constraints
  validates :name, presence: true
  # key uniqueness enforced by database constraints
  validates :key, presence: true

  validate :contains_only_local_users

  ##
  # @param hostname [String]
  # @param ip [String]
  # @return [Enumerable<UserGroup>]
  # @see Host#all_matching_hostname_or_ip
  #
  def self.all_matching_hostname_or_ip(hostname, ip)
    Host.all_matching_hostname_or_ip(hostname, ip).map(&:user_group)
  end

  ##
  # @return [UserGroup] The sysadmin group.
  #
  def self.sysadmin
    UserGroup.find_by_key("sysadmin")
  end

  ##
  # @return [Enumerable<User>] All users either directly associated with the
  #         instance or being in an LDAP group associated with the instance.
  #
  def all_users
    self.users + User.joins("INNER JOIN ldap_groups_users ON ldap_groups_users.user_id = users.id").
        where("ldap_groups_users.ldap_group_id IN (?)", self.ldap_group_ids)
  end

  def breadcrumb_label
    name
  end

  ##
  # @param user [User]
  # @return [Boolean] Whether the given user is either directly associated with
  #         the instance of is in an LDAP group associated with the instance.
  #
  def includes?(user)
    self.users.include?(user) ||
      User.joins("INNER JOIN ldap_groups_users ON ldap_groups_users.user_id = users.id").
        where("ldap_groups_users.ldap_group_id IN (?)", self.ldap_group_ids).
        where(id: user.id).count > 0
  end


  private

  def contains_only_local_users
    if self.users.where.not(type: LocalUser.to_s).count > 0
      errors.add(:users, "can contain only local users")
    end
  end

end
