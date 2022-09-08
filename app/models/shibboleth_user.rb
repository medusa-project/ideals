# frozen_string_literal: true

##
# Concrete implementation of {User}. This type of user comes from the
# Shibboleth authentication strategy. All Shibboleth users have NetIDs and
# whether they are a {sysadmin? sysadmin} is determined by their membership in
# the {UserGroup#sysadmin sysadmin user group}.
#
class ShibbolethUser < User

  ##
  # @return [ShibbolethUser]
  #
  def self.from_omniauth(auth)
    auth = auth.deep_stringify_keys
    user = ShibbolethUser.find_by(uid: auth["uid"])
    if user
      user.update_with_omniauth(auth)
    else
      user = ShibbolethUser.create_with_omniauth(auth)
    end
    user
  end

  ##
  # Used in assignment of permissions to NetID users, but not using Active
  # Directory.
  # HERE BE DRAGONS
  # such as the fire-breathing "This person's role in the org changed, but we did not change permission in IDEALS"
  def self.no_omniauth(email)
    email_string = email.to_s.strip
    raise ArgumentError, "email address required" unless email && !email_string.empty?
    raise ArgumentError, "valid email address required" unless email_string.match(URI::MailTo::EMAIL_REGEXP)

    ShibbolethUser.find_by(email: email) ||
      ShibbolethUser.create_no_omniauth(email: email_string)
  end

  def self.create_no_omniauth(email:)
    create! do |user|
      user.uid   = email
      user.email = email
      user.name  = email.split("@").first
    end
  end

  def self.create_with_omniauth(auth)
    user = ShibbolethUser.new
    user.update_with_omniauth(auth)
    user
  end

  def self.netid_from_email(email)
    return nil unless email.respond_to?(:split)
    netid = email.split("@").first
    return nil if netid.blank?
    netid
  end

  ##
  # Performs an LDAP query to determine whether the instance belongs to the
  # given group.
  #
  # N.B.: in development and test environments, no query is executed, and
  # instead the return value is `true` if the NetID and group name both include
  # the string `admin`.
  #
  # @param group [AdGroup,String]
  # @return [Boolean]
  #
  def belongs_to_ad_group?(group)
    group = group.to_s
    if Rails.env.development? || Rails.env.test?
      return self.netid.include?("sysadmin") && group.include?("sysadmin") # TODO: redesign how this works
    end
    user = UiucLibAd::Entity.new(entity_cn: self.netid)
    begin
      return user.is_member_of?(group_cn: group)
    rescue UiucLibAd::NoDNFound
      return false
    end
  end

  def netid
    self.class.netid_from_email(self.email)
  end

  ##
  # @return [Boolean]
  #
  def sysadmin?
    UserGroup.sysadmin.ad_groups.find{ |g| self.belongs_to_ad_group?(g) }.present?
  end

  def update_with_omniauth(auth)
    auth = auth.deep_stringify_keys
    # By design, logging in overwrites certain existing user properties with
    # current information from the Shib IdP. By supplying this custom
    # attribute, we can preserve the user properties that are set up in test
    # fixture data.
    return if auth.dig("extra", "raw_info", "overwriteUserAttrs") == "false"

    # N.B.: we must access the auth hash carefully because not all properties
    # will be present in all environments; in particular, in development, we
    # are using omniauth's developer strategy which doesn't supply much.
    self.uid         = auth["uid"] || auth["info"]["email"]
    self.email       = auth["info"]["email"]
    self.name        = "#{auth.dig("extra", "raw_info", "givenName")} "\
                       "#{auth.dig("extra", "raw_info", "sn")}"
    self.name        = self.uid if self.name.blank?
    self.org_dn      = auth.dig("extra", "raw_info", "org-dn")
    self.institution = Institution.find_by_org_dn(self.org_dn)
    self.phone       = auth.dig("extra", "raw_info", "telephoneNumber")
    self.affiliation = Affiliation.from_shibboleth(auth)
    dept             = auth.dig("extra", "raw_info", "departmentCode")
    self.department  = Department.create!(name: dept) if dept
    begin
      self.save!
    rescue => e
      @message = IdealsMailer.error_body(e,
                                         message: "[user: #{self.as_json}]\n[auth hash: #{auth.as_json}]",
                                         user:    self)
      Rails.logger.error(@message)
      IdealsMailer.error(@message).deliver_now unless Rails.env.development?
    end
  end

end
