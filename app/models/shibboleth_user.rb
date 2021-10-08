# frozen_string_literal: true

##
# Concrete implementation of {User}. This type of user comes from the
# Shibboleth authentication strategy. All Shibboleth users have NetIDs and
# whether they are a {sysadmin? sysadmin} is determined by their membership in
# an AD group ascribed to the {UserGroup#sysadmin sysadmin user group}.
#
class ShibbolethUser < User

  UIUC_ORG_DN = "o=University of Illinois at Urbana-Champaign,dc=uiuc,dc=edu"

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

  def self.fetch_ldap_groups(auth)
    groups = []
    auth.dig("extra", "raw_info", "member")&.split(";")&.each do |group_urn|
      groups << LdapGroup.find_or_create_by(urn: group_urn)
    end
    groups
  end

  def self.display_name(email)
    netid = netid_from_email(email)
    begin
      response = URI.open("https://quest.library.illinois.edu/directory/ad/person/#{netid}").read
      xml_doc = Nokogiri::XML(response)
      xml_doc.remove_namespaces!
      display_name = xml_doc.xpath("//attr[@name='displayname']").text
      display_name.strip!
      display_name
    rescue OpenURI::HTTPError
      netid
    end
  end

  def self.netid_from_email(email)
    return nil unless email.respond_to?(:split)
    netid = email.split("@").first
    return nil if netid.blank?
    netid
  end

  def self.org_dn(auth)
    dn = auth.dig("extra", "raw_info", "org-dn")
    unless dn
      if auth["info"]["email"].split("@").last == "illinois.edu"
        dn = UIUC_ORG_DN
      end
    end
    dn
  end

  def netid
    self.class.netid_from_email(self.email)
  end

  ##
  # @return [Boolean]
  #
  def sysadmin?
    (UserGroup.sysadmin.ldap_groups & self.ldap_groups).any?
  end

  def update_with_omniauth(auth)
    auth = auth.deep_stringify_keys
    # By design, logging in wipes out certain existing user properties and
    # replaces them with current information from the Shib IdP. By supplying
    # this custom attribute, we can preserve the user properties that are set
    # up in test fixture data.
    return if auth.dig("extra", "raw_info", "overwriteUserAttrs") == "false"

    # N.B.: we must access the auth hash carefully because not all properties
    # will be present in all environments; in particular, in development, we
    # are using omniauth's developer strategy which doesn't supply much.
    self.uid         = auth["uid"]
    self.email       = auth["info"]["email"]
    self.name        = "#{auth.dig("extra", "raw_info", "givenName")} "\
                       "#{auth.dig("extra", "raw_info", "sn")}"
    self.org_dn      = self.class.org_dn(auth)
    self.ldap_groups = self.class.fetch_ldap_groups(auth)
    self.affiliation = Affiliation.from_shibboleth(auth)
    dept             = auth.dig("extra", "raw_info", "departmentCode")
    self.department  = Department.create!(name: dept) if dept
    self.save!
  end

end
