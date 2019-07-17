# frozen_string_literal: true

# This type of user comes from the identity authentication strategy

require_relative "../user"
require_relative '../../app/models/identity'
require_relative '../../app/models/invitee'

class User::Identity < User::User
  def self.from_omniauth(auth)
    return nil unless auth && auth[:uid] && auth["info"]["email"]

    email = auth["info"]["email"].strip
    identity = Identity.find_by(email: email)

    return nil unless identity&.activated

    user = User::Identity.find_by(provider: auth["provider"], uid: auth["uid"])
    if user
      user.update_with_omniauth(auth)
    else
      user = User::Identity.create_with_omniauth(auth)
    end
    user
  end

  def self.create_with_omniauth(auth)
    invitee = Invitee.find_by(email: auth["info"]["email"])
    return nil unless invitee&.expires_at

    return nil unless invitee.expires_at >= Time.current

    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.email = auth["info"]["email"]
      user.name = auth["info"]["name"]
      user.username = user.email
      user.role = user_role(user.email)
    end
  end

  def update_with_omniauth(auth)
    update!(provider: auth["provider"],
            uid:      auth["uid"],
            email:    auth["info"]["email"],
            username: email.split("@").first,
            name:     auth["info"]["name"],
            role:     User::Identity.user_role(email))
  end

  def self.user_role(email)
    invitee = Invitee.find_by(email: email)
    return Ideals::UserRole::GUEST unless invitee

    invitee.role
  end

  def self.can_deposit(email)
    if rails_env.test? || rails_env.development?
      # admin permission is handled elsewhere
      user_role(email) == Ideals::UserRole::DEPOSITOR
    else
      # in production and demo systems, only Shibboleth users can deposit
      false
    end
  end

  def self.display_name(email)
    identity = find_by(email: email)
    return email unless identity

    identity.name || email
  end
end
