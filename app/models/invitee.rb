# frozen_string_literal: true

##
# Non-NetID user who has either been invited to register, or has requested to
# register, and may or may not yet have a corresponding {LocalIdentity
# identity}.
#
# # Invitation/Registration Flow
#
# This class is the entry point into the local-user account model. Instances
# are created in response to two events:
#
# 1. A sysadmin invites a user to register. In this case, a sysadmin fills an
#    email address into a private form. This creates an instance that is pre-
#    {ApprovalState#APPROVED approved} to register. An email is sent to that
#    address containing a link to the registration form. The link includes a
#    `token` query argument containing a value that authorizes access to the
#    form.
# 2. A user requests to register. In this case, the user fills their email
#    address and a purpose statement into form and submits it. The user
#    receives an email confirmation of the request. Sysadmins also receive
#    emails notifying them that action is required (either approval or
#    rejection) on the user's request to register.
#     a. If approved, the user receives an email telling them such and a link
#        to the registration form, as in (1). The {Invitee} instance is marked
#        as {ApprovalState::APPROVED approved}.
#     b. If rejected, the user receives an email telling them such and the
#        {Invitee} instance is marked as {ApprovalState::REJECTED rejected}.
# 3. At this point, assuming the user is approved, the "paths" merge. The user
#    accesses the registration form, filling in their info.
# 4. Upon successful form submission, the user receives a welcome email.
#
# # Attributes
#
# * `approval_state`    One of the {ApprovalState} constant values.
# * `created_at`        Managed by ActiveRecord.
# * `email`             Email address.
# * `expires_at`        Time after which invite is no longer valid.
# * `institution_admin` If true, signifies that the corresponding {User} that
#                       is to be created should be an administrator of the
#                       institution referenced by {institution_id}.
# * `institution_id`    Foreign key to {Institution} signifying the institution
#                       into which the invitee is being invited.
# * `inviting_user_id`  Foreign key to {User} indicating the user who invited
#                       the invitee to register. This is null in the case of
#                       "self-invited" invitees.
# * `purpose`           Contains the "purpose" that the user entered when
#                       requesting an account. For users who were invited and
#                       did not request their account, this is autofilled with
#                       such a notice.
# * `rejection_reason`  Contains the reason entered by an administrator who has
#                       rejected the invitee.
# * `updated_at`        Managed by ActiveRecord.
#
class Invitee < ApplicationRecord

  include Breadcrumb

  class ApprovalState
    PENDING  = 'pending'
    APPROVED = 'approved'
    REJECTED = 'rejected'

    ##
    # @return [Enumerable<String>]
    #
    def self.all
      self.constants.map{ |k| const_get(k) }
    end
  end

  EXPIRATION = 1.year

  has_one :identity, class_name: "LocalIdentity", inverse_of: :invitee
  belongs_to :institution, optional: true
  belongs_to :inviting_user, class_name: "User", optional: true

  before_create -> { self.expires_at = EXPIRATION.from_now }

  validates :email, presence: true # uniqueness is validated in a custom method
  validates :purpose, presence: true

  validate :validate_email_uniqueness, on: :create

  ##
  # Approves a user-initiated self-invite.
  #
  # @see invite
  # @see reject
  #
  def approve
    associate_or_create_identity
    self.update!(approval_state: ApprovalState::APPROVED)
    send_approval_email
  end

  def approved?
    approval_state == ApprovalState::APPROVED
  end

  def breadcrumb_label
    self.email
  end

  def breadcrumb_parent
    Invitee
  end

  def expired?
    self.expires_at && self.expires_at < EXPIRATION.ago
  end

  ##
  # Invites a local-identity user and pre-approves the invite. Should only be
  # invoked by sysadmins.
  #
  # @see approve
  # @see reject
  #
  def invite
    associate_or_create_identity
    self.update!(approval_state: ApprovalState::APPROVED)
    send_invited_email
  end

  def pending?
    approval_state == ApprovalState::PENDING
  end

  ##
  # @param reason [String] Optional.
  # @see approve
  # @see invite
  #
  def reject(reason: nil)
    self.update!(approval_state:   ApprovalState::REJECTED,
                 rejection_reason: reason)
    send_rejection_email
  end

  def rejected?
    approval_state == ApprovalState::REJECTED
  end

  def send_approval_email
    unless approved?
      raise "An approval email can only be sent to an approved invitee."
    end
    associate_or_create_identity
    self.identity.create_registration_digest
    self.identity.send_approval_email
  end

  def send_invited_email
    unless approved?
      raise "An invite email can only be sent to an approved invitee."
    end
    self.identity.create_registration_digest
    self.identity.send_invited_email
  end

  ##
  # Sends two emails:
  #
  # 1. A confirmation to the invitee that their request was received;
  # 2. A message to sysadmins that the invitee has requested to register.
  #
  def send_reception_emails
    unless pending?
      raise "A reception email can only be sent to a pending invitee."
    end
    IdealsMailer.account_request_received(self).deliver_now
    IdealsMailer.account_request_action_required(self).deliver_now
  end

  def send_rejection_email
    unless rejected?
      raise "An rejection email can only be sent to a pending invitee."
    end
    mail = IdealsMailer.account_denied(self)
    mail.deliver_now
  end

  ##
  # @return [User] Associated instance, or `nil` if not yet registered.
  #
  def user
    @user = User.find_by(email: self.email) unless @user
    @user
  end


  private

  def associate_or_create_identity # TODO: redesign as associate_or_create_user
    unless self.identity
      id = LocalIdentity.find_by(email: self.email)
      if id
        self.update!(identity: id)
      else
        # A password is required, so just set a random one. It will be updated
        # during registration.
        password = LocalIdentity.random_password
        user     = User.find_by_email(self.email) ||
          User.create!(email:       self.email,
                       name:        self.email,
                       institution: self.institution)
        LocalIdentity.create!(email:                 self.email,
                              password:              password,
                              password_confirmation: password,
                              invitee:               self,
                              user:                  user)
      end
    end
  end

  ##
  # Supplement to the built-in email validation that also ensures that the
  # email has not been taken by any {User}s.
  #
  def validate_email_uniqueness
    if Invitee.where.not(id: self.id).where(email: self.email).exists? ||
      User.where(email: self.email).exists?
      errors.add(:email, "has already been taken")
    end
  end

end
