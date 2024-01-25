# frozen_string_literal: true

##
# Encapsulates a user account.
#
# # Institution Membership
#
# The process by which a user is made a member of an institution varies
# depending on the authentication method:
#
# * For local authentication, the user either requests to join a particular
#   institution, or is invited into a particular institution by a sysadmin at
#   the time they are invited to register.
# * For SAML authentication, the user is made a member of the institution
#   matching the request host at login.
#
# # Attributes
#
# * `caching_submittable_collections_task_id` Set to the ID of the {Task}
#                                       associated with a
#                                       {CacheSubmittableCollectionsJob} while
#                                       it's working.
# * `created_at`                        Managed by ActiveRecord.
# * `email`                             Email address.
# * `enabled`                           Whether the user is able to log in.
# * `institution_id`                    Foreign key to {Institution}
#                                       representing the institution of which
#                                       the user is a member. Non-sysadmin
#                                       users can only log into and browse
#                                       around their home institution's space
#                                       in the IR.
# * `name`                              The user's name.
# * `updated_at`                        Managed by ActiveRecord.
# * `submittable_collections_cached_at` The last time
#                                       {cached_submittable_collections} was
#                                       updated.
#
class User < ApplicationRecord

  include Breadcrumb

  # Only UIUC users will have one of these.
  belongs_to :affiliation, optional: true
  belongs_to :caching_submittable_collections_task, class_name: "Task",
             optional: true
  belongs_to :institution, optional: true
  # Only UIUC users will have one of these.
  has_one :department
  has_one :credential, inverse_of: :user
  # This relationship is not "live" - it needs to be populated manually
  # (typically by effective_submittable_collections?()).
  has_many :cached_submittable_collections, class_name: "SubmittableCollection"
  has_many :collection_administrators
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
  # `UserGroup.includes?()`
  has_and_belongs_to_many :user_groups

  validates :email, presence: true, length: {maximum: 255},
            format: {with: StringUtils::EMAIL_REGEX}
  validates_uniqueness_of :email, case_sensitive: false
  validates :name, presence: true

  before_save :sync_credential_properties

  ##
  # @param auth [OmniAuth::AuthHash]
  # @return [User] Instance corresponding to the given auth hash, or nil if not
  #                found.
  #
  def self.fetch_from_omniauth_local(auth)
    auth  = auth.deep_symbolize_keys
    email = auth.dig(:info, :email)
    User.find_by_email(email)
  end

  ##
  # @param auth [OmniAuth::AuthHash]
  # @param email_location [Integer] One of the {Institution::SAMLEmailLocation}
  #                                 constant values.
  # @param email_attribute [String] Required if email_location is
  #                                 {Institution::SAMLEmailLocation#ATTRIBUTE}.
  # @return [User] Instance corresponding to the given auth hash, or nil if not
  #                found.
  #
  def self.fetch_from_omniauth_saml(auth,
                                    email_location:,
                                    email_attribute: "emailAddress")
    auth  = auth.deep_symbolize_keys

    case email_location
    when Institution::SAMLEmailLocation::ATTRIBUTE
      attrs = auth[:extra][:raw_info].attributes.deep_stringify_keys
      email = attrs[email_attribute]&.first
    else
      email = auth[:uid]
    end

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
  # @param auth [OmniAuth::AuthHash, Hash]
  # @param institution [Institution] The returned user will be assigned to this
  #        institution. (Only applies to SAML users. Local credential users
  #        will be assigned to the institution of the corresponding {Invitee}.)
  # @return [User] Instance corresponding to the given auth hash. If one was
  #                not found, it is created.
  #
  def self.from_omniauth(auth, institution:)
    case auth[:provider]
    when "saml", "developer"
      User.from_omniauth_saml(auth, institution: institution)
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
    user.save!
    user
  end

  ##
  # @private
  #
  def self.from_omniauth_saml(auth, institution:)
    user = User.fetch_from_omniauth_saml(auth,
                                         email_location:  institution.saml_email_location,
                                         email_attribute: institution.saml_email_attribute)
    user ||= User.new
    user.send(:update_from_omniauth_saml, auth, institution)
    user
  end

  ##
  # Performs an LDAP query to determine whether the instance belongs to the
  # given AD group. Groups are exposed only to UIUC users.
  #
  # N.B.: in development and test environments, no query is executed, and
  # instead the return value is `true` if the `ad.groups` key in the
  # configuration includes the user's email.
  #
  # @param group [AdGroup,String]
  # @return [Boolean]
  #
  def belongs_to_ad_group?(group)
    group = group.to_s
    if Rails.env.development? || Rails.env.test?
      groups = Configuration.instance.ad.dig(:groups, self.email)
      return groups&.include?(group)
    end

    return false unless self.email.end_with?("@illinois.edu")
    cache_key = Digest::MD5.hexdigest("#{self.email} ismemberof #{group}")
    Rails.cache.fetch(cache_key, expires_in: 12.hours) do
      begin
        user = UiucLibAd::User.new(cn: self.netid)
        user.is_member_of?(group_cn: group)
      rescue UiucLibAd::NoDNFound
        false
      end
    end
  end

  def breadcrumb_label
    self.name
  end

  def breadcrumb_parent
    User
  end

  ##
  # @param collection [Collection]
  # @param client_ip [String]
  # @param client_hostname [String]
  # @return [Boolean] Whether the instance is a direct administrator of the
  #                   given collection.
  # @see #effective_collection_admin?
  #
  def collection_admin?(collection,
                        client_ip:       nil,
                        client_hostname: nil)
    return true if collection.administrators.find{ |a| a.user_id == self.id }
    collection.administering_groups.each do |group|
      return true if group.includes?(user:            self,
                                     client_ip:       client_ip,
                                     client_hostname: client_hostname)
    end
    false
  end

  ##
  # @param collection [Collection]
  # @param client_ip [String]
  # @param client_hostname [String]
  # @return [Boolean] Whether the instance is a direct submitter of the given
  #                   collection.
  # @see #effective_collection_submitter?
  #
  def collection_submitter?(collection,
                            client_ip:       nil,
                            client_hostname: nil)
    return true if collection.submitters.find{ |s| s.user_id == self.id }
    collection.submitting_groups.each do |group|
      return true if group.includes?(user:            self,
                                     client_ip:       client_ip,
                                     client_hostname: client_hostname)
    end
    false
  end

  ##
  # @param collection [Collection]
  # @param client_ip [String]
  # @param client_hostname [String]
  # @param consider_sysadmin [Boolean] If false, the user's sysadmin status
  #                                    (which would cause a true return value)
  #                                    will not be checked for/considered.
  # @param consider_institution_admin [Boolean] If false, the user's
  #                                             institution administrator
  #                                             status (which would cause a
  #                                             true return value) will not be
  #                                             checked for/considered.
  # @return [Boolean] Whether the instance is an effective administrator of the
  #                   given collection, either directly or as a unit or system
  #                   administrator.
  # @see #collection_administrator?
  #
  def effective_collection_admin?(collection,
                                  client_ip:                  nil,
                                  client_hostname:            nil,
                                  consider_sysadmin:          true,
                                  consider_institution_admin: true)
    # Check for sysadmin.
    return true if consider_sysadmin &&
      sysadmin?(client_ip:       client_ip,
                client_hostname: client_hostname)
    # Check for institution admin.
    return true if consider_institution_admin &&
      institution_admin?(collection&.institution,
                         client_ip:       client_ip,
                         client_hostname: client_hostname)
    # Check for unit admin.
    # There may be cases where primary_unit is set but units aren't (such as
    # new collections that haven't been persisted yet).
    return true if effective_unit_admin?(collection.primary_unit,
                                         client_ip:       client_ip,
                                         client_hostname: client_hostname)
    collection.all_units.each do |unit|
      return true if effective_unit_admin?(unit,
                                           client_ip:       client_ip,
                                           client_hostname: client_hostname)
    end
    # Check for administrator of the collection itself.
    return true if collection_admin?(collection,
                                     client_ip:       client_ip,
                                     client_hostname: client_hostname)
    # Check all of its parent collections.
    collection.all_parents.each do |parent|
      return true if collection_admin?(parent,
                                       client_ip: client_ip,
                                       client_hostname: client_hostname)
    end
    false
  end

  ##
  # @param collection [Collection]
  # @param client_ip [String]
  # @param client_hostname [String]
  # @param consider_sysadmin [Boolean] If false, the user's sysadmin status
  #                                    (which would cause a true return value)
  #                                    will not be checked for/considered.
  # @param consider_institution_admin [Boolean] If false, the user's
  #                                             institution administrator
  #                                             status (which would cause a
  #                                             true return value) will not be
  #                                             checked for/considered.
  # @return [Boolean] Whether the instance is an effective submitter in the
  #                   given collection, either directly or as a collection,
  #                   unit, institution, or system administrator.
  # @see #collection_submitter?
  #
  def effective_collection_submitter?(collection,
                                      client_ip:                  nil,
                                      client_hostname:            nil,
                                      consider_sysadmin:          true,
                                      consider_institution_admin: true)
    return true if effective_collection_admin?(collection,
                                               client_ip:                  client_ip,
                                               client_hostname:            client_hostname,
                                               consider_sysadmin:          consider_sysadmin,
                                               consider_institution_admin: consider_institution_admin)
    # Check the collection itself.
    return true if collection_submitter?(collection,
                                         client_ip:       client_ip,
                                         client_hostname: client_hostname)
    # Check all of its parent collections.
    collection.all_parents.each do |parent|
      return true if collection_submitter?(parent,
                                           client_ip:       client_ip,
                                           client_hostname: client_hostname)
    end
    false
  end

  ##
  # @param institution [Institution]
  # @param client_ip [String]
  # @param client_hostname [String]
  # @return [Boolean] Whether the instance is effectively an administrator of
  #                   the given institution.
  #
  def effective_institution_admin?(institution,
                                   client_ip:       nil,
                                   client_hostname: nil)
    sysadmin?(client_ip:       client_ip,
              client_hostname: client_hostname) ||
      institution_admin?(institution,
                         client_ip:       client_ip,
                         client_hostname: client_hostname)
  end

  ##
  # N.B.: this is expensive and slows as the collection count increases.
  # Consider invoking {CacheSubmittableCollectionsJob} and then reading
  # {cached_submittable_collections}.
  #
  # @param client_ip [String]
  # @param client_hostname [String]
  # @param task [Task] Supply to receive progress updates.
  # @return [Enumerable<Collection>] All collections to which the user is
  #         authorized to submit an item.
  #
  def effective_submittable_collections(client_ip:,
                                        client_hostname:,
                                        task:            nil)
    collections = self.institution.collections.where(accepts_submissions: true,
                                                     buried:              false)
    if self.effective_institution_admin?(self.institution,
                                         client_ip:       client_ip,
                                         client_hostname: client_hostname)
      task&.succeed
      return collections
    end
    count                   = collections.count
    submittable_collections = []
    collections.each_with_index do |collection, index|
      if self.effective_collection_submitter?(collection,
                                              client_ip:                  client_ip,
                                              client_hostname:            client_hostname,
                                              consider_sysadmin:          false,
                                              consider_institution_admin: false)
        submittable_collections << collection
      end
      if index % 10 == 0
        task&.progress((index + 1) / count.to_f)
      end
    end
    task&.succeed
    submittable_collections
  end

  ##
  # @param unit [Unit]
  # @param client_ip [String]
  # @param client_hostname [String]
  # @return [Boolean] Whether the instance is effectively an administrator of
  #                   the given unit.
  # @see unit_admin?
  #
  def effective_unit_admin?(unit, client_ip: nil, client_hostname: nil)
    # Check to see whether the user is an administrator of the unit's
    # institution.
    return true if effective_institution_admin?(unit.institution,
                                                client_ip:       client_ip,
                                                client_hostname: client_hostname)
    # Check to see whether the user is an administrator of the unit itself.
    return true if unit_admin?(unit,
                               client_ip:       client_ip,
                               client_hostname: client_hostname)
    # Check all of its parent units.
    unit.all_parents.each do |parent|
      return true if unit_admin?(parent,
                                 client_ip:       client_ip,
                                 client_hostname: client_hostname)
    end
    false
  end

  ##
  # @param institution [Institution]
  # @param client_ip [String]
  # @param client_hostname [String]
  # @return [Boolean] Whether the instance is a direct administrator of the
  #                   given institution.
  #
  def institution_admin?(institution, client_ip: nil, client_hostname: nil)
    return false unless institution
    # Check for a directly assigned administrator.
    return true if institution.administrators.where(user_id: self.id).exists?
    # Check for membership in an administering user group.
    institution.administering_groups.each do |group|
      return true if group.includes?(user:            self,
                                     client_ip:       client_ip,
                                     client_hostname: client_hostname)
    end
    false
  end

  ##
  # @return [Invitee]
  #
  def invitee
    @invitee = Invitee.find_by_email(self.email) unless @invitee
    @invitee
  end

  ##
  # @return [String] The NetID (the user component of the email). This works
  #                  regardless of authentication method, even though
  #                  technically only UofI users have NetIDs.
  #
  def netid
    return nil unless self.email.respond_to?(:split)
    netid = self.email.split("@").first
    return nil if netid.blank?
    netid
  end

  ##
  # @param client_ip [String]
  # @param client_hostname [String]
  # @return [Boolean] Whether the user is a system administrator, i.e. can do
  #                   absolutely anything.
  #
  def sysadmin?(client_ip:, client_hostname:)
    UserGroup.sysadmin.includes?(user:            self,
                                 client_ip:       client_ip,
                                 client_hostname: client_hostname)
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
  # @return [String]
  #
  def to_s
    self.email
  end

  ##
  # @param unit [Unit]
  # @param client_ip [String]
  # @param client_hostname [String]
  # @return [Boolean] Whether the instance is a direct administrator of the
  #                   given unit (not considering its parents).
  # @see effective_unit_admin?
  #
  def unit_admin?(unit, client_ip: nil, client_hostname: nil)
    return true if unit.administrators.find{ |a| a.user_id == self.id }
    unit.administering_groups.each do |group|
      return true if group.includes?(user:            self,
                                     client_ip:       client_ip,
                                     client_hostname: client_hostname)
    end
    false
  end


  private

  ##
  # Updates the relevant properties of the associated {Credential} to match
  # those of the instance.
  #
  def sync_credential_properties
    if self.email_changed?
      id = Credential.find_by_email(self.email_was)
      id&.update_attribute(:email, self.email)
    end
  end

  ##
  # @param auth [OmniAuth::AuthHash]
  # @param institution [Institution] Only set if the instance does not already
  #                                  have an institution set.
  #
  def update_from_omniauth_saml(auth, institution)
    auth  = auth.deep_symbolize_keys
    # raw_info will be nil when using the developer strategy
    attrs = {}
    if auth[:extra] && auth[:extra][:raw_info]
      attrs = auth[:extra][:raw_info].attributes.deep_stringify_keys
    end

    # By design, logging in overwrites certain existing user properties with
    # current information from the IdP. By supplying this custom attribute,
    # we can preserve the user properties that are set up in test fixture data.
    return if attrs['overwriteUserAttrs'] == "false"

    self.institution ||= institution
    case institution.saml_email_location
    when Institution::SAMLEmailLocation::ATTRIBUTE
      self.email = attrs[institution.saml_email_attribute]&.first
    else
      self.email = auth[:uid]
    end
    self.name = [attrs[institution.saml_first_name_attribute]&.first,
                 attrs[institution.saml_last_name_attribute]&.first].join(" ").strip
    self.name = self.email if self.name.blank?

    # Only UIUC users will be expected to have these.
    self.affiliation = Affiliation.from_omniauth(attrs)
    self.department  = Department.from_omniauth(attrs)
    begin
      self.save!
    rescue => e
      @message = IdealsMailer.error_body(e,
                                         detail: "[user: #{YAML::dump(self)}]\n\n"\
                                                 "[auth hash: #{YAML::dump(auth)}]",
                                         user:   self)
      Rails.logger.error(@message)
      IdealsMailer.error(@message).deliver_later unless Rails.env.development?
    end
  end

end
