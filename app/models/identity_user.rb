# frozen_string_literal: true

##
# Concrete implementation of {User}. This type of user is created, stored, and
# managed locally. Users are preferentially {ShibbolethUser}s, but some users
# (including local development and test users) may not have NetIDs, thus the
# need for this type.
#
# For this type of user, the {sysadmin} column determines whether they are a
# sysadmin.
#
class IdentityUser < User

  before_destroy :destroy_local_identity

  def self.from_omniauth(auth)
    return nil unless auth && auth[:uid] && auth["info"]["email"]

    email = auth["info"]["email"].strip
    identity = Identity.find_by(email: email)

    return nil unless identity&.activated

    user = IdentityUser.find_by(email: email)
    if user
      user.update_with_omniauth(auth)
    else
      user = IdentityUser.create_with_omniauth(auth)
    end
    user
  end

  def self.create_no_omniauth(email)
    create! do |user|
      user.uid      = email
      user.email    = email
      user.username = email
      user.name     = email
    end
  end

  def self.create_with_omniauth(auth)
    email = auth["info"]["email"].strip
    return nil unless email

    invitee = Invitee.find_by(email: email)
    return nil unless invitee&.expires_at
    return nil unless invitee.expires_at >= Time.current

    create! do |user|
      user.uid      = email
      user.email    = email
      user.name     = auth["info"]["name"]
      user.username = email
    end
  end

  def self.no_omniauth(email)
    IdentityUser.create_no_omniauth(email) unless IdentityUser.exists?(email: email)
    IdentityUser.find_by(email: email)
  end

  def update_with_omniauth(auth)
    email = auth["info"]["email"].strip
    return nil unless email

    update!(uid:      email,
            email:    email,
            username: email.split("@").first,
            name:     auth["info"]["name"])
  end

  def self.display_name(email)
    identity = find_by(email: email)
    return email unless identity

    identity.name || email
  end

  ##
  # @return [Identity]
  #
  def identity
    Identity.find_by_email(self.email)
  end

  def sysadmin?
    sysadmin
  end

  private

  def destroy_local_identity
    Identity.destroy_by(email: self.email)
  end

end
