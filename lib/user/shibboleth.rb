# frozen_string_literal: true

# This type of user comes from the shibboleth authentication strategy

require_relative "../user"

class User::Shibboleth < User::User
  def self.from_omniauth(auth)
    return nil unless auth && auth[:uid]

    user = User::Shibboleth.find_by(provider: auth["provider"], uid: auth["uid"])

    if user
      user.update_with_omniauth(auth)
    else
      user = User::Shibboleth.create_with_omniauth(auth)
    end

    user
  end

  # used in assignment of permissions to NetID users, but not using Active Directory.
  # HERE BE DRAGONS
  # such as the fire-breathing "This person's role in the org changed, but we did not change permission in IDEALS"
  def self.no_omniauth(email)
    email_string = email.to_s.strip
    raise ArgumentError, "email address required" unless email && !email_string.empty?

    raise ArgumentError, "valid email address required" unless email_string.match(URI::MailTo::EMAIL_REGEXP)

    user = User.find_by(email: email, provider: Ideals::AuthProvider::SHIBBOLETH)
    if user
      user.role = role
      user.save!
    else
      user = User::Shibboleth.create_no_omniauth(email: email_string, role: role)
    end
    user
  end

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.email = auth["info"]["email"]
      user.username = (auth["info"]["email"]).split("@").first
      user.name = display_name((auth["info"]["email"]).split("@").first)
    end
  end

  def self.create_no_omniauth(email)
    create! do |user|
      user.provider = Ideals::AuthProvider::SHIBBOLETH
      user.uid = email
      user.email = email
      user.username = email.split("@").first
      user.name = email.split("@").first
    end
  end

  def update_with_omniauth(auth)
    update!(
      provider: auth["provider"],
      uid:      auth["uid"],
      email:    auth["info"]["email"],
      username: (auth["info"]["email"]).split("@").first,
      name:     User::Shibboleth.display_name((auth["info"]["email"]).split("@").first)
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
end
