# frozen_string_literal: true

##
# Aggregation of {User}s, {AdGroup}s, and other dimensions, for the purpose of
# performing group-based authorization.
#
# User groups can be global or scoped to an institution. Global groups can only
# be created or edited by system administrators.
#
# User groups have human-readable {#name names}. They also have a {#key} that
# is unique within the same scope. The key is generally used only within the
# application to get a handle on certain {#SYSTEM_REQUIRED_GROUPS
# system-required groups}. For those groups, it is fixed and known. For other
# groups, like whatever arbitrary groups are created within an institution, it
# is auto-filled with a random string.
#
# When an {Institution} is created, a group that represents it is created along
# with it. This group is considered to {UserGroup#defines_institution define
# the institution}.
#
# # Attributes
#
# * `created_at`          Managed by ActiveRecord.
# * `defines_institution` Whether the group defines the users in its owning
#                         institution. Every institution should have one such
#                         group.
# * `institution_id`      Foreign key to {Institution} indicating that the
#                         group is exclusive to that institution. May also be
#                         `nil`, indicating that the group is global, available
#                         to all institutions.
# * `key`                 Short string identifier that is unique within an
#                         institutional scope. This is generally used only
#                         within the application to get a handle on certain
#                         {#SYSTEM_REQUIRED_GROUPS system-required groups}.
# * `name`                Arbitrary human-readable name that is unique within
#                         an institutional scope.
# * `updated_at`          Managed by ActiveRecord.
#
class UserGroup < ApplicationRecord
  include Breadcrumb

  # The key given to a user group that {#defining_institution defines its
  # institution}.
  DEFINING_INSTITUTION_KEY = "institution"
  # Key of the sysadmin group.
  SYSADMIN_KEY             = "sysadmin"
  # The application needs these groups to exist.
  SYSTEM_REQUIRED_GROUPS   = %w(sysadmin)

  belongs_to :institution, optional: true

  has_many :ad_groups
  has_many :bitstream_authorizations
  has_many :collection_administrator_groups
  has_many :departments
  has_many :email_patterns
  has_many :hosts
  has_many :submitter_groups
  has_many :unit_administrator_groups

  has_and_belongs_to_many :affiliations
  has_and_belongs_to_many :embargoes
  has_and_belongs_to_many :users

  validates :name, presence: true # uniqueness enforced by database constraints
  validates :key, presence: true  # uniqueness enforced by database constraints
  validate :validate_sysadmin_group

  after_save :ensure_defines_institution_uniqueness
  before_destroy :prevent_destroy_of_required_group

  before_validation :ascribe_key, if: :new_record?

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
    self.users +
      User.where(auth_method: User::AuthMethod::SHIBBOLETH).
        select{ |u| u.belongs_to_user_group?(self) }
  end

  def breadcrumb_label
    name
  end

  def breadcrumb_parent
    UserGroup
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
  # OR (is a Shibboleth user AND belongs to an associated AD Group)
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
    (user.shibboleth? &&
      self.ad_groups.find{ |g| user.belongs_to_ad_group?(g) }.present?)
  end

  ##
  # @return [ActiveRecord::Relation<User>]
  #
  def local_users
    self.users.where(auth_method: User::AuthMethod::LOCAL)
  end

  ##
  # @return [ActiveRecord::Relation<User>]
  #
  def netid_users
    self.users.where(auth_method: User::AuthMethod::SHIBBOLETH)
  end

  ##
  # @return [Boolean] Whether the group is required by the system. Required
  #                   groups can be modified but not deleted.
  #
  def required?
    self.defines_institution || SYSTEM_REQUIRED_GROUPS.include?(self.key)
  end


  private

  def ascribe_key
    if self.key.blank?
      if self.defines_institution
        self.key = DEFINING_INSTITUTION_KEY
      else
        self.key = SecureRandom.hex
      end
    end
  end

  ##
  # Marks all other instances of the same institution as "not defining the
  # institution" if the instance is marked as defining the institution.
  #
  def ensure_defines_institution_uniqueness
    if self.defines_institution
      self.class.all.
        where(institution_id: self.institution_id).
        where("id != ?", self.id).each do |instance|
        instance.update!(defines_institution: false)
      end
    end
  end

  def prevent_destroy_of_required_group
    if SYSTEM_REQUIRED_GROUPS.include?(self.key)
      errors.add(:base, :undestroyable)
      throw :abort
    end
  end

  ##
  # Ensures that there is only one group with a key of {SYSADMIN_KEY}.
  #
  def validate_sysadmin_group
    if self.key == SYSADMIN_KEY && self.institution_id.present?
      errors.add(:key, "cannot be that of the system administrator group")
      throw :abort
    end
  end

end
