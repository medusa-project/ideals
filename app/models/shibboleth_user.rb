# frozen_string_literal: true

##
# Concrete implementation of {User}. This type of user comes from the
# Shibboleth authentication strategy. All Shibboleth users have NetIDs and
# whether they are a {sysadmin? sysadmin} is determined by their membership in
# an LDAP group ascribed to the {UserGroup#sysadmin sysadmin user group}.
#
class ShibbolethUser < User

  ##
  # @return [ShibbolethUser]
  #
  def self.from_omniauth(auth)
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

  def self.create_no_omniauth(email)
    create! do |user|
      user.uid   = email
      user.email = email
      user.name  = email.split("@").first
    end
  end

  def self.create_with_omniauth(auth)
    create! do |user|
      user.uid         = auth["uid"]
      user.email       = auth["info"]["email"]
      user.name        = display_name((auth["info"]["email"]).split("@").first)
      user.ldap_groups = fetch_ldap_groups(auth)
    end
  end

  def self.fetch_ldap_groups(auth)
    groups = []
    auth['extra']['raw_info']['member'].split(";").each do |group_urn|
      groups << LdapGroup.find_or_create_by(urn: group_urn)
    end
    groups
  end

  def update_with_omniauth(auth)
    update!(uid:         auth["uid"],
            email:       auth["info"]["email"],
            name:        ShibbolethUser.display_name((auth["info"]["email"]).split("@").first),
            ldap_groups: self.class.fetch_ldap_groups(auth))
  end

  def self.display_name(email)
    netid = netid_from_email(email)

    return "Unknown" unless netid

    begin
      response = URI.open("https://quest.library.illinois.edu/directory/ad/person/#{netid}").read
      xml_doc = Nokogiri::XML(response)
      xml_doc.remove_namespaces!
      display_name = xml_doc.xpath("//attr[@name='displayname']").text
      display_name.strip!
      display_name
    rescue OpenURI::HTTPError
      "Unknown"
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

  ##
  # @return [Boolean]
  #
  def sysadmin?
    !(UserGroup.sysadmin.ldap_groups & self.ldap_groups).empty?
  end

end
