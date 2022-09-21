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
class LocalUser < User

  before_save :sync_identity_properties
  before_destroy :destroy_identity

  ##
  # This is mainly for quickly creating local administrators in development.
  # It should not be used in production as it does not proceed through the
  # ordinary invitation & registration workflow.
  #
  # @param email [String]
  # @param password [String]
  # @param institution [Institution] If not provided, the user will be placed
  #        in the [Institution#default default institution].
  # @param name [String] If not provided, the email is used.
  # @return [LocalUser]
  #
  def self.create_manually(email:, password:, institution: nil, name: nil)
    institution ||= Institution.default
    ActiveRecord::Base.transaction do
      invitee = Invitee.find_by_email(email)
      unless invitee
        invitee = Invitee.create!(email:          email,
                                  institution:    institution,
                                  approval_state: ApprovalState::APPROVED,
                                  note:           "Created as a sysadmin on the "\
                                                  "command line, bypassing the "\
                                                  "invitation process")
      end
      identity = LocalIdentity.find_by_email(email)
      unless identity
        identity = LocalIdentity.create!(email:                 email,
                                         name:                  name || email,
                                         password:              password,
                                         password_confirmation: password,
                                         invitee:               invitee,
                                         activated:             true,
                                         activated_at:          Time.zone.now)
      end
      identity.build_user(email:       email,
                          uid:         email,
                          institution: institution,
                          name:        name || email,
                          type:        LocalUser.to_s)
    end
  end

  ##
  # Private; use {from_omniauth} instead.
  #
  def self.create_with_omniauth(auth)
    email = auth[:info][:email].strip
    return nil unless email

    invitee = Invitee.find_by(email: email)
    return nil unless invitee&.expires_at
    return nil unless invitee.expires_at >= Time.current

    create! do |user|
      user.uid   = email
      user.email = email
      user.name  = auth[:info][:name]
    end
  end

  ##
  # @param auth [Hash]
  # @return [LocalUser] Instance corresponding to the given OmniAuth hash.
  #                     Only instances with {LocalIdentity#activated activated
  #                     identities} are returned.
  #
  def self.from_omniauth(auth)
    auth = auth.deep_symbolize_keys
    return nil unless auth && auth[:uid] && auth[:info][:email]

    email    = auth[:info][:email].strip
    identity = LocalIdentity.find_by(email: email)

    return nil unless identity&.activated

    user = LocalUser.find_by(uid: email)
    if user
      user.update_with_omniauth(auth)
    else
      user = LocalUser.create_with_omniauth(auth)
    end
    user
  end

  ##
  # @return [Boolean] Whether the associated {Identity} has been activated,
  #                   i.e. is allowed to log in.
  #
  def activated?
    identity.activated
  end

  ##
  # @return [Boolean]
  #
  def sysadmin?
    self.user_groups.include?(UserGroup.sysadmin)
  end

  def update_with_omniauth(auth)
    email = auth[:info][:email].strip
    return nil unless email

    update!(uid:   email,
            email: email,
            name:  auth[:info][:name])
  end

  private

  def destroy_identity
    LocalIdentity.destroy_by(email: self.email)
  end

  ##
  # Updates the relevant properties of the associated {LocalIdentity} to match
  # those of the instance.
  #
  def sync_identity_properties
    id = LocalIdentity.find_by_email(self.email_was)
    if id
      id.update_attribute(:email, self.email) if self.email_changed?
      id.update_attribute(:name, self.name) if self.name_changed?
    end
  end

end
