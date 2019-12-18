# frozen_string_literal: true

# This type of user comes from the identity authentication strategy

require_relative "../user"
require_relative "../../app/models/identity"
require_relative "../../app/models/invitee"

class User::Identity < User::User
  def self.from_omniauth(auth)
    return nil unless auth && auth[:uid] && auth["info"]["email"]

    email = auth["info"]["email"].strip
    identity = Identity.find_by(email: email)

    return nil unless identity&.activated

    user = User::Identity.find_by(provider: Ideals::AuthProvider::IDENTITY, email: email)
    if user
      user.update_with_omniauth(auth)
    else
      user = User::Identity.create_with_omniauth(auth)
    end
    user
  end

  def self.create_with_omniauth(auth)
    email = auth["info"]["email"].strip
    return nil unless email

    invitee = Invitee.find_by(email: email)
    return nil unless invitee&.expires_at

    return nil unless invitee.expires_at >= Time.current

    create! do |user|
      user.provider = auth["provider"]
      user.uid = email
      user.email = email
      user.name = auth["info"]["name"]
      user.username = email
    end
  end

  def update_with_omniauth(auth)
    email = auth["info"]["email"].strip
    return nil unless email

    update!(provider: Ideals::AuthProvider::IDENTITY,
            uid:      email,
            email:    email,
            username: email.split("@").first,
            name:     auth["info"]["name"])
  end

  def self.display_name(email)
    identity = find_by(email: email)
    return email unless identity

    identity.name || email
  end
end
