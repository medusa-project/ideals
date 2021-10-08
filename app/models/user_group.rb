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
  has_many :departments
  has_many :hosts
  has_many :manager_groups
  has_many :submitter_groups

  has_and_belongs_to_many :affiliations
  has_and_belongs_to_many :ldap_groups
  # LocalUsers only!
  has_and_belongs_to_many :users

  validates :name, presence: true # uniqueness enforced by database constraints
  validates :key, presence: true # uniqueness enforced by database constraints

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
  # Returns whether the given user is considered to be a member of the
  # instance. Membership is determined by the following logic:
  #
  # ```
  # (belongs to an associated AD Group) OR (is a directly associated LocalUser) OR
  #   ((belongs to an associated department) AND (is of an associated affiliation))
  # ```
  #
  # @param user [User]
  # @return [Boolean]
  #
  def includes?(user)
    if user.is_a?(LocalUser)
      return true if self.users.include?(user)
    else
      return true if User.
        joins("INNER JOIN ldap_groups_users ON ldap_groups_users.user_id = users.id").
        where("ldap_groups_users.ldap_group_id IN (?)", self.ldap_group_ids).
        where(id: user.id).
        count > 0
      dept_names = self.departments.pluck(:name)
      if dept_names.any?
        if dept_names.include?(user.department&.name)
          aff_ids = self.affiliations.pluck(:id)
          if aff_ids.any?
            return aff_ids.include?(user.affiliation_id)
          end
          return true
        end
      end
    end
    false
  end


  private

  def contains_only_local_users
    if self.users.where.not(type: LocalUser.to_s).count > 0
      errors.add(:users, "can contain only local users")
    end
  end

end
