# frozen_string_literal: true

##
# Concrete implementation of {User}. This type of user comes from the
# Shibboleth authentication strategy. All Shibboleth users have NetIDs and
# whether they are a {sysadmin? sysadmin} is determined by their membership in
# an LDAP group ascribed to the {UserGroup#sysadmin sysadmin user group}.
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

    user = ShibbolethUser.find_by(email: email)
    unless user
      user = ShibbolethUser.create_no_omniauth(email: email_string)
    end
    user
  end

  def self.create_no_omniauth(email:)
    create! do |user|
      user.uid   = email
      user.email = email
      user.name  = email.split("@").first
    end
  end

  def self.create_with_omniauth(auth)
    auth = auth.deep_stringify_keys
    # By design, logging in wipes out certain existing user properties and
    # replaces them with current information from the Shib IdP. By supplying
    # this custom attribute, we can preserve the user properties that are set
    # up in test fixture data.
    #
    # N.B.: we must access the auth hash carefully because not all properties
    # will be present in all environments; for example, in development, we are
    # using omniauth's developer strategy which doesn't supply much.
    return if auth.dig("extra", "raw_info", "overwriteUserAttrs") == "false"
    create! do |user|
      user.uid         = auth["uid"]
      user.email       = auth["info"]["email"]
      user.name        = display_name((auth["info"]["email"]).split("@").first)
      user.org_dn      = org_dn(auth)
      user.ldap_groups = fetch_ldap_groups(auth)
    end
  end

  def self.fetch_ldap_groups(auth)
    groups = []
    auth.dig("extra", "raw_info", "member")&.split(";")&.each do |group_urn|
      groups << LdapGroup.find_or_create_by(urn: group_urn)
    end
    groups
  end

  def update_with_omniauth(auth)
    # see inline comment in create_with_omniauth()
    return if auth.dig("extra", "raw_info", "overwriteUserAttrs") == "false"
    self.uid         = auth["uid"]
    self.email       = auth["info"]["email"]
    self.name        = self.class.display_name(auth["info"]["email"].split("@").first)
    self.org_dn      = self.class.org_dn(auth)
    self.ldap_groups = self.class.fetch_ldap_groups(auth)
    self.save!
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
    return nil unless netid.respond_to?(:length) && !netid.empty?

    netid
  end

  def netid
    self.class.netid_from_email(self.email)
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

  ##
  # @return [Boolean]
  #
  def sysadmin?
    !(UserGroup.sysadmin.ldap_groups & self.ldap_groups).empty?
  end

end
