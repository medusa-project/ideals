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

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.email = auth["info"]["email"]
      user.username = (auth["info"]["email"]).split("@").first
      user.name = display_name((auth["info"]["email"]).split("@").first)
      user.role = user_role(auth["uid"])
    end
  end

  def update_with_omniauth(auth)
    update!(
      provider: auth["provider"],
      uid:      auth["uid"],
      email:    auth["info"]["email"],
      username: (auth["info"]["email"]).split("@").first,
      name:     User::Shibboleth.display_name((auth["info"]["email"]).split("@").first),
      role:     User::Shibboleth.user_role(auth["uid"])
    )
  end

  def self.user_role(email)
    role = Ideals::UserRole::GUEST

    if email.respond_to?(:split)

      netid = email.split("@").first

      if netid.respond_to?(:length) && !netid.empty?
        admins = IDEALS_CONFIG[:admin][:netids].split(",").map {|x| x.strip || x }
        role = Ideals::UserRole::ADMIN if admins.include?(netid)
      end
    end
    role
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
