# frozen_string_literal: true

##
# Non-NetID user who has either been invited to register, or has self-
# petitioned to register, and may or may not yet have an {Identity}.
#
# # Attributes
#
# * `approval_state`: One of the {ApprovalState} constant values.
# * `created_at`:     Managed by ActiveRecord.
# * `email`:          Email address.
# * `expires_at`:     Time that the invite is no longer valid.
# * `note`:
# * `updated_at`:     Managed by ActiveRecord.
#
class Invitee < ApplicationRecord

  EXPIRATION = 1.year

  has_one :identity, inverse_of: :invitee

  after_create :associate_or_create_identity

  validates :email, presence: true, uniqueness: true

  before_destroy -> { identity&.destroy!; user&.destroy! }

  def self.pendings
    Invitee.where(approval_state: ApprovalState::PENDING)
  end

  def self.approveds
    Invitee.where(approval_state: ApprovalState::APPROVED)
  end

  def self.rejecteds
    Invitee.where(approval_state: ApprovalState::REJECTED)
  end

  def expired?
    self.expires_at && self.expires_at < EXPIRATION.ago
  end

  ##
  # @return [IdentityUser] Associated instance, or `nil` if not yet registered.
  #
  def user
    @user = IdentityUser.find_by(email: email) unless @user
    @user
  end

  private

  def associate_or_create_identity
    self.identity = Identity.find_by(email: email)
    unless self.identity
      # Set a random password. It will be updated during registration.
      password = SecureRandom.hex
      self.identity = Identity.create!(email:                 self.email,
                                       name:                  self.email,
                                       password:              password,
                                       password_confirmation: password,
                                       invitee:               self,
                                       activated:             true,
                                       activated_at:          Time.zone.now)
    end
  end

end
