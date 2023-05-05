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
  def self.create_manually(email:, password:, institution:, name: nil)
    ActiveRecord::Base.transaction do
      invitee = Invitee.find_by_email(email)
      unless invitee
        invitee = Invitee.create!(email:          email,
                                  institution:    institution,
                                  approval_state: Invitee::ApprovalState::APPROVED,
                                  note:           "Created as a sysadmin on the "\
                                                  "command line, bypassing the "\
                                                  "invitation process")
      end
      identity = LocalIdentity.find_by_email(email)
      unless identity
        identity = LocalIdentity.create!(email:                 email,
                                         password:              password,
                                         password_confirmation: password,
                                         invitee:               invitee)
      end
      identity.build_user(email:       email,
                          institution: institution,
                          name:        name || email,
                          type:        LocalUser.to_s)
    end
  end

  ##
  # Private method used by {from_omniauth}.
  #
  # @private
  #
  def self.create_with_omniauth(auth)
    auth    = auth.deep_symbolize_keys
    email   = auth.dig(:info, :email)&.strip
    invitee = Invitee.find_by(email: email)
    return nil unless invitee&.expires_at
    return nil unless invitee.expires_at >= Time.current

    create! do |user|
      user.email       = email
      user.name        = email
      user.institution = invitee.institution
    end
  end

  ##
  # @param auth [Hash]
  # @return [LocalUser] Instance corresponding to the given OmniAuth hash.
  #
  def self.from_omniauth(auth)
    auth  = auth.deep_symbolize_keys
    email = auth.dig(:info, :email)&.strip
    LocalUser.find_by(email: email) || LocalUser.create_with_omniauth(auth)
  end

  ##
  # @return [Boolean]
  #
  def sysadmin?
    self.user_groups.include?(UserGroup.sysadmin)
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
    if self.email_changed?
      id = LocalIdentity.find_by_email(self.email_was)
      id.update_attribute(:email, self.email) if id
    end
  end

end
