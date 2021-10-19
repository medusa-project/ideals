##
# Aggregation of [LocalUser]s, [LdapGroup]s, and other dimensions, for the
# purpose of performing group-based authorization.
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
  has_many :departments
  has_many :hosts
  has_many :manager_groups
  has_many :submitter_groups

  has_and_belongs_to_many :affiliations
  has_and_belongs_to_many :ldap_groups
  has_and_belongs_to_many :users

  validates :name, presence: true # uniqueness enforced by database constraints
  validates :key, presence: true # uniqueness enforced by database constraints

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
  # Returns whether the given user is considered to be a member of the
  # instance. Membership is determined by the following logic:
  #
  # ```
  # (is a directly associated User) OR (belongs to an associated AD Group) OR
  # (belongs to an associated department) OR (is of an associated affiliation)
  # ```
  #
  # @param user [User]
  # @return [Boolean]
  #
  def includes?(user)
    # is a directly associated User
    self.users.where(id: user.id).count.positive? ||
    # belongs to an associated AD group
    User.joins("INNER JOIN ldap_groups_users ON ldap_groups_users.user_id = users.id").
      where("ldap_groups_users.ldap_group_id IN (?)", self.ldap_group_ids).
      where(id: user.id).
      count.positive? ||
    # belongs to an associated department
    self.departments.where(name: user.department&.name).count.positive? ||
    # is of an associated affiliation
    self.affiliations.where(id: user.affiliation_id).count.positive?
  end

  ##
  # @return [ActiveRecord::Relation<LocalUser>]
  #
  def local_users
    self.users.where(type: LocalUser.to_s)
  end

  ##
  # @return [ActiveRecord::Relation<ShibbolethUser>]
  #
  def netid_users
    self.users.where(type: ShibbolethUser.to_s)
  end

end
