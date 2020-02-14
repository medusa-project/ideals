# frozen_string_literal: true

##
# Concrete implementation of {User}. This type of user comes from the
# shibboleth authentication strategy. All Shibboleth users have NetIDs and
# whether or not they are a {sysadmin? sysadmin} is determined by their
# membership in the AD group named in the `admin/ad_group` configuration key.
#
class ShibbolethUser < User

  validate :sysadmin_not_allowed

  def self.from_omniauth(auth)
    return nil unless auth && auth[:uid]

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

  def self.create_with_omniauth(auth)
    create! do |user|
      user.uid      = auth["uid"]
      user.email    = auth["info"]["email"]
      user.username = (auth["info"]["email"]).split("@").first
      user.name     = display_name((auth["info"]["email"]).split("@").first)
    end
  end

  def self.create_no_omniauth(email)
    create! do |user|
      user.uid      = email
      user.email    = email
      user.username = email.split("@").first
      user.name     = email.split("@").first
    end
  end

  def update_with_omniauth(auth)
    update!(
      uid:      auth["uid"],
      email:    auth["info"]["email"],
      username: (auth["info"]["email"]).split("@").first,
      name:     ShibbolethUser.display_name((auth["info"]["email"]).split("@").first)
    )
  end

  def self.display_name(email)
    netid = netid_from_email(email)

    return "Unknown" unless netid

    begin
      response = open("http://quest.grainger.uiuc.edu/directory/ed/person/#{netid}").read
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

  ##
  # @return [Boolean]
  #
  def sysadmin?
    group = Configuration.instance.admin[:ad_group]
    LdapQuery.new.is_member_of?(group, self.username)
  end

  private

  ##
  # Ensures that the `sysadmin` property is not set to `true`, as this is only
  # available for {IdentityUser}s. For instances of this class, sysadmin-ness
  # is obtained from Active Directory.
  #
  def sysadmin_not_allowed
    if self.sysadmin
      errors.add(:sysadmin, "cannot be set to true for #{self.class}s")
    end
  end

end
