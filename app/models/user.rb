# frozen_string_literal: true

##
# Abstract class representing a user. Concrete implementations are subclasses
# using Rails single-table inheritance. (Basically this just means that their
# class name is stored in the `type` column.)
#
# # Institution Membership
#
# The process by which a user is made a member of an institution varies
# depending on the subclass:
#
# * For [LocalUser]s, the user either requests to join a particular
#   institution, or is invited into a particular institution by a sysadmin at
#   the time they are invited to register.
# * For [ShibbolethUser]s, the user's "org DN" provided by the IdP is matched
#   against an [Institution]'s {Institution#org_dn} property at login.
#
# # Attributes
#
# * `auth_hash`         Serialized OmniAuth hash that was supplied at last
#                       login, composed of information from the Shibboleth IdP.
# * `created_at`        Managed by ActiveRecord.
# * `email`             Email address.
# * `institution_id`    Foreign key to [Institution] representing the
#                       institution of which the instance is a member.
# * `last_logged_in_at` Date/time of last login.
# * `local_identity_id` Foreign key to [LocalIdentity]. Used only by
#                       [LocalUser]s; set during processing of the
#                       registration form.
# * `name`              The user's name in whatever format they choose to
#                       provide it.
# * `org_dn`            `eduPersonOrgDN` property supplied by Shibboleth. Only
#                       [ShibbolethUser]s have this. TODO: this is probably not needed anymore now that we have institution_id
# * `phone`             The user's phone number.
# * `type`              Supports Rails single-table inheritance (STI).
# * `uid`               For [ShibbolethUser]s, this is the UID provided by
#                       Shibboleth (which is probably the EPPN). For
#                       [IdentityUser]s, it's the email address.
# * `updated_at:        Managed by ActiveRecord.
#
class User < ApplicationRecord

  include Breadcrumb

  # ShibbolethUsers only!
  belongs_to :affiliation, optional: true
  belongs_to :identity, class_name: "LocalIdentity",
             foreign_key: "local_identity_id", inverse_of: :user, optional: true
  belongs_to :institution, optional: true
  has_one :department
  has_many :events
  has_many :institution_administrators
  has_many :administering_institutions, through: :institution_administrators,
           source: :institution
  has_many :invitees, inverse_of: :inviting_user, foreign_key: :inviting_user_id
  has_many :managers
  has_many :managing_collections, through: :managers, source: :collection
  has_many :primary_administering_units, class_name: "Unit",
           inverse_of: :primary_administrator
  has_many :submitted_items, class_name: "Item", foreign_key: "submitter_id",
           inverse_of: :submitter
  has_many :submitters
  has_many :submitting_collections, through: :submitters, source: :collection
  has_many :tasks
  # ShibbolethUsers only!
  has_many :unit_administrators
  has_many :administering_units, through: :unit_administrators, source: :unit
  # This includes only directly assigned user groups. See `belongs_to_user_group?()`
  has_and_belongs_to_many :user_groups

  validates :email, presence: true, length: {maximum: 255},
            format: {with: StringUtils::EMAIL_REGEX}
  validates_uniqueness_of :email, case_sensitive: false
  validates :name, presence: true
  validates :uid, presence: true
  validates_uniqueness_of :uid, case_sensitive: false

  serialize :auth_hash

  ##
  # @param string [String] Autocomplete text field string.
  # @return [User] Instance corresponding to the given string. May be `nil`.
  # @see to_autocomplete
  #
  def self.from_autocomplete_string(string)
    if string.present?
      # user strings may be in one of two formats: "Name (email)" or "email"
      tmp = string.scan(/\((.*)\)/).last
      email = tmp ? tmp.first : string
      return User.find_by_email(email)
    end
    nil
  end

  ##
  # @param user_group [UserGroup]
  # @return [Boolean]
  #
  def belongs_to_user_group?(user_group)
    user_group.includes?(self)
  end

  def breadcrumb_label
    self.name
  end

  def breadcrumb_parent
    User
  end

  ##
  # @param institution [Institution]
  # @return [Boolean] Whether the instance is effectively an administrator of
  #                   the given institution.
  #
  def effective_institution_admin?(institution)
    sysadmin? || institution_admin?(institution)
  end

  ##
  # @param collection [Collection]
  # @return [Boolean] Whether the instance is an effective manager of the given
  #                   collection, either directly or as a unit or system
  #                   administrator.
  # @see #manager?
  #
  def effective_manager?(collection) # TODO: rename to effective_collection_manager?
    # Check for sysadmin.
    return true if sysadmin?
    # Check for institution admin.
    return true if institution_admin?(collection.institution)
    # Check for unit admin.
    collection.all_units.each do |unit|
      return true if effective_unit_admin?(unit)
    end
    # Check for manager of the collection itself.
    return true if manager?(collection)
    # Check all of its parent collections.
    collection.all_parents.each do |parent|
      return true if manager?(parent)
    end
    false
  end

  ##
  # @return [Enumerable<Collection>] All collections to which the user is
  #         authorized to submit an item.
  #
  def effective_submittable_collections
    if effective_institution_admin?(self.institution)
      return Collection.joins(:units).where("units.institution_id = ?",
                                            self.institution_id)
    end
    collections  = Set.new
    collections += self.administering_units.map(&:collections).flatten
    collections += self.managing_collections
    collections += self.submitting_collections
    collections
  end

  ##
  # @param collection [Collection]
  # @return [Boolean] Whether the instance is an effective submitter in the
  #                   given collection, either directly or as a collection
  #                   manager or unit, institution, or system administrator.
  # @see #submitter?
  #
  def effective_submitter?(collection) # TODO: rename to effective_collection_submitter?
    return true if effective_manager?(collection)
    # Check the collection itself.
    return true if submitter?(collection)
    # Check all of its parent collections.
    collection.all_parents.each do |parent|
      return true if submitter?(parent)
    end
    false
  end

  ##
  # @param unit [Unit]
  # @return [Boolean] Whether the instance is effectively an administrator of
  #                   the given unit.
  # @see unit_admin?
  #
  def effective_unit_admin?(unit)
    # Check to see whether the user is an administrator of the unit's
    # institution.
    return true if effective_institution_admin?(unit.institution)
    # Check to see whether the user is an administrator of the unit itself.
    return true if unit_admin?(unit)
    # Check all of its parent units.
    unit.all_parents.each do |parent|
      return true if unit_admin?(parent)
    end
    false
  end

  ##
  # @param institution [Institution]
  # @return [Boolean] Whether the instance is a direct administrator of the
  #                   given institution.
  #
  def institution_admin?(institution)
    return false unless institution
    # Check for a directly assigned administrator.
    return true if institution.administrators.where(user_id: self.id).count > 0
    # Check for membership in an administering user group.
    institution.administering_groups.each do |group|
      return true if self.belongs_to_user_group?(group)
    end
    false
  end

  ##
  # @param collection [Collection]
  # @return [Boolean] Whether the instance is a direct manager of the given
  #                   collection.
  # @see #effective_manager?
  #
  def manager?(collection) # TODO: rename to collection_manager?
    return true if collection.managers.where(user_id: self.id).count > 0
    collection.managing_groups.each do |group|
      return true if self.belongs_to_user_group?(group)
    end
    false
  end

  ##
  # @param collection [Collection]
  # @return [Boolean] Whether the instance is a direct submitter of the given
  #                   collection.
  # @see #effective_submitter?
  #
  def submitter?(collection) # TODO: rename to collection_submitter?
    return true if collection.submitters.where(user_id: self.id).count > 0
    collection.submitting_groups.each do |group|
      return true if self.belongs_to_user_group?(group)
    end
    false
  end

  ##
  # @return [Boolean] Whether the user is a system administrator, i.e. can do
  #                   absolutely anything.
  #
  def sysadmin?
    raise "Subclasses must override sysadmin?()"
  end

  ##
  # @return [String] The instance's name and/or email formatted for an
  #                  autocomplete text field.
  # @see from_autocomplete_string
  #
  def to_autocomplete
    # N.B.: changing this probably requires changing some JavaScript and
    # controller code.
    name.present? ? "#{name} (#{email})" : email
  end

  ##
  # @param unit [Unit]
  # @return [Boolean] Whether the instance is a direct administrator of the
  #                   given unit (not considering its parents).
  # @see effective_unit_admin?
  #
  def unit_admin?(unit)
    return true if unit.administrators.where(user_id: self.id).count > 0
    unit.administering_groups.each do |group|
      return true if self.belongs_to_user_group?(group)
    end
    false
  end

end
