##
# Aggregation of [LocalUser]s, [AdGroup]s, and other dimensions, for the
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

  has_many :ad_groups
  has_many :administrator_groups
  has_many :bitstream_authorizations
  has_many :departments
  has_many :email_patterns
  has_many :hosts
  has_many :manager_groups
  has_many :submitter_groups

  has_and_belongs_to_many :affiliations
  has_and_belongs_to_many :embargoes
  has_and_belongs_to_many :users

  validates :name, presence: true # uniqueness enforced by database constraints
  validates :key, presence: true  # uniqueness enforced by database constraints

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
  #         instance or belonging to an AD group associated with the instance.
  #
  def all_users
    self.users + User.
        joins("INNER JOIN ad_groups ON ad_groups.user_id = users.id").
        where("ad_groups.name IN (?)", self.ad_groups.map(&:name))
  end

  def breadcrumb_label
    name
  end

  ##
  # Returns whether the given user is considered to be a member of the
  # instance. Membership is determined by the following logic:
  #
  # ```
  # (is a directly associated User)
  # OR (has an email address matching one of the email patterns)
  # OR (belongs to an associated department)
  # OR (is of an associated affiliation)
  # OR (is a ShibbolethUser AND belongs to an associated AD Group)
  # ```
  #
  # @param user [User]
  # @return [Boolean]
  #
  def includes?(user)
    # is a directly associated User
    self.users.where(id: user.id).count.positive? ||
    # has a matching email address
    self.email_patterns.find{ |p| p.matches?(user.email) }.present? ||
    # belongs to an associated department
    self.departments.where(name: user.department&.name).count.positive? ||
    # is of an associated affiliation
    self.affiliations.where(id: user.affiliation_id).count.positive? ||
    # belongs to an associated AD group
    # (this check comes last because it is the most expensive)
    (user.kind_of?(ShibbolethUser) &&
      self.ad_groups.find{ |g| user.belongs_to_ad_group?(g) }.present?)
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
