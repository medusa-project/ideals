# frozen_string_literal: true

##
# Encapsulates a user account.
#
# # Authentication Methods
#
# Users can sign in via several {AuthMethod methods}. Their last (and current)
# sign-in method is assigned to the {auth_method} attribute.
#
# # Institution Membership
#
# The process by which a user is made a member of an institution varies
# depending on the {auth_method authentication method}:
#
# * For local authentication, the user either requests to join a particular
#   institution, or is invited into a particular institution by a sysadmin at
#   the time they are invited to register.
# * For Shibboleth authentication, the user's "org DN" provided by the IdP is
#   matched against an institution's {Institution#shibboleth_org_dn} property
#   at login.
# * For OpenAthens authentication, the user's "organization ID" provided by the
#   OpenAthens IdP is matched against an institution's
#   {Institution#openathens_organization_id} property at login.
#
# # Attributes
#
# * `auth_method`       One of the {User::AuthMethod} constant values
#                       representing the authentication method used at the last
#                       login.
# * `created_at`        Managed by ActiveRecord.
# * `email`             Email address.
# * `enabled`           Whether the user is able to log in.
# * `institution_id`    Foreign key to {Institution} representing the
#                       institution of which the instance is a member. All non-
#                       sysadmin users can only log into and browse around
#                       their home institution's space in the IR.
# * `local_identity_id` Foreign key to {LocalIdentity}. Used only with
#                       {User::AuthMethod::LOCAL local authentication}; set
#                       during processing of the registration form.
# * `name`              The user's name in whatever format they choose to
#                       provide it.
# * `phone`             The user's phone number.
# * `updated_at:        Managed by ActiveRecord.
#
class User < ApplicationRecord

  include Breadcrumb

  class AuthMethod
    # Credentials are stored in the users table.
    LOCAL      = 0
    # Used only by UIUC.
    SHIBBOLETH = 1
    # Used by many CARLI member institutions.
    OPENATHENS = 2
  end

  # Only Shibboleth users will have one of these.
  belongs_to :affiliation, optional: true
  belongs_to :identity, class_name: "LocalIdentity",
             foreign_key: "local_identity_id", inverse_of: :user, optional: true
  belongs_to :institution, optional: true
  # Only Shibboleth users will have one of these.
  has_one :department
  has_many :collection_administrators, class_name: "CollectionAdministrator"
  has_many :events
  has_many :institution_administrators
  has_many :administering_institutions, through: :institution_administrators,
           source: :institution
  has_many :invitees, inverse_of: :inviting_user, foreign_key: :inviting_user_id
  has_many :logins
  has_many :administering_collections, through: :collection_administrators,
           source: :collection
  has_many :primary_administering_units, class_name: "Unit",
           inverse_of: :primary_administrator
  has_many :submitted_items, class_name: "Item", foreign_key: "submitter_id",
           inverse_of: :submitter
  has_many :submitters, class_name: "CollectionSubmitter"
  has_many :submitting_collections, through: :submitters, source: :collection
  has_many :tasks
  has_many :unit_administrators
  has_many :administering_units, through: :unit_administrators, source: :unit
  # This includes only directly assigned user groups. See
  # `belongs_to_user_group?()`
  has_and_belongs_to_many :user_groups

  validates :email, presence: true, length: {maximum: 255},
            format: {with: StringUtils::EMAIL_REGEX}
  validates_uniqueness_of :email, case_sensitive: false
  validates :name, presence: true

  before_save :sync_identity_properties
  before_destroy :destroy_identity

  ##
  # This is used for quickly creating local administrators in development. It
  # should not be used in production as it does not proceed through the normal
  # invitation & registration workflow.
  #
  # @param email [String]
  # @param password [String]
  # @param institution [Institution]
  # @param name [String] If not provided, the email is used.
  # @return [User]
  #
  def self.create_local(email:, password:, institution:, name: nil)
    ActiveRecord::Base.transaction do
      invitee = Invitee.find_by_email(email)
      unless invitee
        invitee = Invitee.create!(email:          email,
                                  institution:    institution,
                                  approval_state: Invitee::ApprovalState::APPROVED,
                                  note:           "Created as a sysadmin "\
                                                  "manually, bypassing the "\
                                                  "invitation process")
      end
      identity = LocalIdentity.find_by_email(email)
      unless identity
        identity = LocalIdentity.create!(email:                 email,
                                         password:              password,
                                         password_confirmation: password,
                                         invitee:               invitee)
      end
      identity.build_user(email:       email,
                          institution: institution,
                          name:        name || email,
                          auth_method: AuthMethod::LOCAL)
    end
  end

  ##
  # @param auth [OmniAuth::AuthHash]
  # @return [User]
  #
  def self.fetch_from_omniauth_local(auth)
    auth  = auth.deep_symbolize_keys
    email = auth.dig(:info, :email)
    User.find_by_email(email)
  end

  ##
  # @param auth [OmniAuth::AuthHash]
  # @return [User]
  #
  def self.fetch_from_omniauth_openathens(auth)
    auth  = auth.deep_symbolize_keys
    attrs = auth[:extra][:raw_info].attributes.deep_symbolize_keys
    email = attrs[:emailAddress]&.first
    User.find_by_email(email)
  end

  ##
  # @param auth [OmniAuth::AuthHash]
  # @return [User]
  #
  def self.fetch_from_omniauth_shibboleth(auth)
    auth  = auth.deep_symbolize_keys
    email = auth.dig(:info, :email)
    User.find_by_email(email)
  end

  ##
  # @param string [String] Autocomplete text field string.
  # @return [User] Instance corresponding to the given string. May be `nil`.
  # @see to_autocomplete
  #
  def self.from_autocomplete_string(string)
    if string.present?
      # user strings may be in one of two formats: "Name (email)" or "email"
      tmp   = string.scan(/\((.*)\)/).last
      email = tmp ? tmp.first : string
      return User.find_by_email(email)
    end
    nil
  end

  ##
  # Obtains (by retrieval or creation) a user matching the given auth hash.
  #
  # @param auth [OmniAuth::AuthHash, Hash]
  # @return [User] One of the concrete implementations.
  #
  def self.from_omniauth(auth)
    case auth[:provider]
    when "developer", "shibboleth"
      User.from_omniauth_shibboleth(auth)
    when "saml"
      User.from_omniauth_openathens(auth)
    when "identity"
      User.from_omniauth_local(auth)
    else
      raise ArgumentError, "Unsupported auth provider"
    end
  end

  ##
  # @private
  #
  def self.from_omniauth_local(auth)
    user = User.fetch_from_omniauth_local(auth)
    unless user
      auth  = auth.deep_symbolize_keys
      email = auth.dig(:info, :email)&.strip
      invitee = Invitee.find_by(email: email)
      return nil unless invitee&.expires_at
      return nil unless invitee.expires_at >= Time.current
      user = User.new(email:       email,
                      name:        email,
                      institution: invitee.institution)
    end
    user.auth_method = AuthMethod::LOCAL
    user.save!
    user
  end

  ##
  # @private
  #
  def self.from_omniauth_openathens(auth)
    user = User.fetch_from_omniauth_openathens(auth) ||
      User.new(auth_method: AuthMethod::OPENATHENS)
    user.send(:update_from_openathens, auth)
    user
  end

  ##
  # @private
  #
  def self.from_omniauth_shibboleth(auth)
    user = User.fetch_from_omniauth_shibboleth(auth) ||
      User.new(auth_method: AuthMethod::SHIBBOLETH)
    user.send(:update_from_shibboleth, auth)
    user
  end

  ##
  # Performs an LDAP query to determine whether the instance belongs to the
  # given group. Works only for {AuthMethod::SHIBBOLETH Shibboleth users}.
  #
  # N.B.: in development and test environments, no query is executed, and
  # instead the return value is `true` if the email and group name both include
  # the string `admin`.
  #
  # @param group [AdGroup,String]
  # @return [Boolean]
  #
  def belongs_to_ad_group?(group)
    return false if auth_method != AuthMethod::SHIBBOLETH
    group = group.to_s
    if Rails.env.development? || Rails.env.test?
      groups = Configuration.instance.ad.dig(:groups, self.email)
      return groups&.include?(group)
    end
    cache_key = Digest::MD5.hexdigest("#{self.institution.key} #{self.netid} ismemberof #{group}")
    Rails.cache.fetch(cache_key, expires_in: 12.hours) do
      begin
        user = UiucLibAd::User.new(cn: self.netid)
        user.is_member_of?(group_cn: group)
      rescue UiucLibAd::NoDNFound
        false
      end
    end
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
  # @param collection [Collection]
  # @return [Boolean] Whether the instance is a direct administrator of the
  #                   given collection.
  # @see #effective_collection_admin?
  #
  def collection_admin?(collection)
    return true if collection.administrators.where(user_id: self.id).count > 0
    collection.administering_groups.each do |group|
      return true if self.belongs_to_user_group?(group)
    end
    false
  end

  ##
  # @param collection [Collection]
  # @return [Boolean] Whether the instance is an effective administrator of the
  #                   given collection, either directly or as a unit or system
  #                   administrator.
  # @see #collection_administrator?
  #
  def effective_collection_admin?(collection)
    # Check for sysadmin.
    return true if sysadmin?
    # Check for institution admin.
    return true if institution_admin?(collection.institution)
    # Check for unit admin.
    collection.all_units.each do |unit|
      return true if effective_unit_admin?(unit)
    end
    # Check for administrator of the collection itself.
    return true if collection_admin?(collection)
    # Check all of its parent collections.
    collection.all_parents.each do |parent|
      return true if collection_admin?(parent)
    end
    false
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
  # @return [Enumerable<Collection>] All collections to which the user is
  #         authorized to submit an item.
  #
  def effective_submittable_collections
    if effective_institution_admin?(self.institution)
      return Collection.joins(:units).
        where(buried: false).
        where("units.institution_id = ?", self.institution_id)
    end
    collections  = Set.new
    collections += self.administering_units.map(&:collections).flatten.reject(&:buried)
    collections += self.administering_collections
    collections += self.submitting_collections
    collections
  end

  ##
  # @param collection [Collection]
  # @return [Boolean] Whether the instance is an effective submitter in the
  #                   given collection, either directly or as a collection,
  #                   unit, institution, or system administrator.
  # @see #submitter?
  #
  def effective_submitter?(collection) # TODO: rename to effective_collection_submitter?
    return true if effective_collection_admin?(collection)
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
  # @return [Boolean]
  #
  def local?
    self.auth_method == AuthMethod::LOCAL
  end

  ##
  # @return [String] The NetID (the user component of the email). This works
  #                  regardless of {auth_method} authentication method, even
  #                  though technically only Shibboleth users have NetIDs.
  #
  def netid
    return nil unless self.email.respond_to?(:split)
    netid = self.email.split("@").first
    return nil if netid.blank?
    netid
  end

  ##
  # @return [Boolean]
  #
  def openathens?
    self.auth_method == AuthMethod::OPENATHENS
  end

  ##
  # @return [Boolean]
  #
  def shibboleth?
    self.auth_method == AuthMethod::SHIBBOLETH
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
    case auth_method
    when AuthMethod::SHIBBOLETH
      self.user_groups.include?(UserGroup.sysadmin) ||
        UserGroup.sysadmin.ad_groups.find{ |g| self.belongs_to_ad_group?(g) }.present?
    else
      self.user_groups.include?(UserGroup.sysadmin)
    end
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


  private

  def destroy_identity
    if auth_method == AuthMethod::LOCAL
      LocalIdentity.destroy_by(email: self.email)
    end
  end

  ##
  # Updates the relevant properties of the associated {LocalIdentity} to match
  # those of the instance.
  #
  def sync_identity_properties
    if auth_method == AuthMethod::LOCAL && self.email_changed?
      id = LocalIdentity.find_by_email(self.email_was)
      id&.update_attribute(:email, self.email)
    end
  end

  ##
  # @param auth [OmniAuth::AuthHash]
  #
  def update_from_openathens(auth)
    auth  = auth.deep_symbolize_keys
    attrs = auth[:extra][:raw_info].attributes.deep_symbolize_keys

    # By design, logging in overwrites certain existing user properties with
    # current information from the IdP. By supplying this custom attribute,
    # we can preserve the user properties that are set up in test fixture data.
    return if attrs[:overwriteUserAttrs] == "false"

    self.auth_method = AuthMethod::OPENATHENS
    self.email       = attrs[:emailAddress]&.first
    self.name        = [attrs[:firstName]&.first, attrs[:lastName]&.first].join(" ").strip
    self.name        = self.email if self.name.blank?
    org_id           = attrs[:"http://eduserv.org.uk/federation/attributes/1.0/organisationid"]
    self.institution = Institution.find_by_openathens_organization_id(org_id) if org_id
    self.phone       = attrs[:phoneNumber]&.first
    begin
      self.save!
    rescue => e
      @message = IdealsMailer.error_body(e,
                                         detail: "[user: #{YAML::dump(self)}]\n\n"\
                                                 "[auth hash: #{YAML::dump(auth)}]",
                                         user:   self)
      Rails.logger.error(@message)
      IdealsMailer.error(@message).deliver_now unless Rails.env.development?
    end
  end

  ##
  # @param auth [OmniAuth::AuthHash]
  #
  def update_from_shibboleth(auth)
    auth = auth.deep_stringify_keys
    # By design, logging in overwrites certain existing user properties with
    # current information from the Shib IdP. By supplying this custom
    # attribute, we can preserve the user properties that are set up in test
    # fixture data.
    return if auth.dig("extra", "raw_info", "overwriteUserAttrs") == "false"

    # N.B.: we have to be careful accessing this hash because not all providers
    # will populate all properties.
    self.auth_method = AuthMethod::SHIBBOLETH
    self.email       = auth["info"]["email"]
    self.name        = "#{auth.dig("extra", "raw_info", "givenName")} "\
                       "#{auth.dig("extra", "raw_info", "sn")}"
    self.name        = self.email if self.name.blank?
    org_dn           = auth.dig("extra", "raw_info", "org-dn")
    # UIS accounts will not have an org DN--eventually these users will be
    # converted into OpenAthens users and moved into the UIS space, and we
    # will fall back to nil here instead of UIUC.
    self.institution = org_dn.present? ?
                         Institution.find_by_shibboleth_org_dn(org_dn) :
                         Institution.find_by_key("uiuc")
    self.phone       = auth.dig("extra", "raw_info", "telephoneNumber")
    self.affiliation = Affiliation.from_shibboleth(auth)
    dept             = auth.dig("extra", "raw_info", "departmentCode")
    self.department  = Department.create!(name: dept) if dept
    begin
      self.save!
    rescue => e
      @message = IdealsMailer.error_body(e,
                                         detail: "[user: #{self.as_json}]\n\n"\
                                                 "[auth hash: #{auth.as_json}]",
                                         user:   self)
      Rails.logger.error(@message)
      IdealsMailer.error(@message).deliver_now unless Rails.env.development?
    end
  end

end
