# frozen_string_literal: true

##
# Local user identity, which hooks into the `omniauth-identity` authentication
# strategy. This is a surrogate of a {User} for users whose credentials are
# stored in the database.
#
# N.B. 1: See the documentation of {Invitee} for a detailed overview of the
# invitation & registration process.
#
# N.B. 2: `omniauth-identity` wants this class to be named `Identity` by
# default. It was renamed to make it immediately clear that these identities
# are managed locally and are not used by all subclasses of {User}.
#
# N.B. 3: The superclass validates {password} and {password_confirmation} on
# update. In order to update an instance without supplying a password, use
# {update_attribute}.
#
# # Attributes
#
# * `created_at`:          Managed by ActiveRecord.
# * `email`:               Email address associated with the instance. This is
#                          often used as an identifier and must be unique.
# * `invitee_id`:          Foreign key to {Invitee}.
# * `lowercase_email`:     The value of {email} gets copied into this column
#                          upon save to support case-insensitive logins.
# * `password_digest`:     Digest of the password, set by {create_for_user}.
# * `registration_digest`: Digest of the registration token, generated by
#                          {create_registration_digest}. Works exactly the same
#                          as {activation_digest}.
# * `reset_digest`:        Digest of the reset token, generated by
#                          {create_reset_digest}. Works exactly the same way as
#                          {activation_digest}.
# * `reset_sent_at`:       Time that {reset_digest} was generated.
# * `user_id`              Foreign key to {User}.
# * `updated_at`:          Managed by ActiveRecord.
#
# @see https://github.com/omniauth/omniauth-identity
#
class LocalIdentity < OmniAuth::Identity::Models::ActiveRecord

  PASSWORD_MIN_LENGTH             = 8
  PASSWORD_MIN_UPPERCASE_LETTERS  = 1
  PASSWORD_MIN_LOWERCASE_LETTERS  = 1
  PASSWORD_MIN_NUMBERS            = 1
  PASSWORD_MIN_SPECIAL_CHARACTERS = 1
  PASSWORD_SPECIAL_CHARACTERS     = "!@#$%^&*"

  attr_accessor :activation_token, :registration_token, :reset_token

  belongs_to :invitee, inverse_of: :identity, optional: true
  belongs_to :user, inverse_of: :identity

  validates :email, presence: true, length: { maximum: 255 },
            format: { with: StringUtils::EMAIL_REGEX },
            uniqueness: { case_sensitive: false }
  validate :validate_password_strength
  validate :validate_invitee_expiration, on: :create

  before_save :set_lowercase_email

  accepts_nested_attributes_for :user, update_only: true

  # Tell omniauth-identity what column to use for lookups; also see
  # config/initializers/omniauth.rb
  auth_key :lowercase_email
  has_secure_password

  ##
  # @param string [String]
  # @return [String] Hash digest of the given string.
  #
  def self.digest(string)
    cost = if ActiveModel::SecurePassword.min_cost
             BCrypt::Engine::MIN_COST
           else
             BCrypt::Engine.cost
           end
    BCrypt::Password.create(string, cost: cost)
  end

  ##
  # @return [String] Random token.
  #
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  ##
  # @return [String] Random valid password.
  #
  def self.random_password
    charset   = Array("A".."Z")
    uppercase = Array.new(6) { charset.sample }.join
    charset   = Array("a".."z")
    lowercase = Array.new(6) { charset.sample }.join
    charset   = Array(1..9)
    numbers   = Array.new(6) { charset.sample }.join
    uppercase + lowercase + numbers + "!"
  end

  ##
  # @return [Boolean] Whether the given token matches the digest stored in the
  #         given attribute.
  #
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  ##
  # Creates and assigns new registration attributes.
  #
  def create_registration_digest
    self.registration_token = LocalIdentity.new_token
    update_attribute(:registration_digest, LocalIdentity.digest(self.registration_token))
  end

  ##
  # Creates and assigns new password reset attributes.
  #
  def create_reset_digest
    self.reset_token = LocalIdentity.new_token
    update_attribute(:reset_digest, LocalIdentity.digest(self.reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  ##
  # @return [String]
  # @raises [RuntimeError] if {reset_token} is blank. (Invoke
  #         {create_reset_digest} to remedy that.)
  #
  def password_reset_url
    raise "Reset token is not set." if self.reset_token.blank?
    sprintf("%s/identities/%d/reset-password?token=%s",
            self.invitee.institution.scope_url,
            self.id,
            self.reset_token)
  end

  ##
  # @return [String]
  # @raises [RuntimeError] if {registration_token} is blank. (Invoke
  #         {create_registration_digest} to remedy that.)
  #
  def registration_url
    raise "Registration token is not set." if self.registration_token.blank?
    sprintf("%s/identities/%d/register?token=%s",
            self.invitee.institution.scope_url,
            self.id,
            self.registration_token)
  end

  ##
  # Sends an email containing a link to the registration form upon approval of
  # an invitee.
  #
  # This is the counterpart of {send_invited_email} for user-initiated self-
  # invites.
  #
  def send_approval_email
    notification = IdealsMailer.account_approved(self)
    notification.deliver_now
  end

  ##
  # Sends an invitation to register for an account.
  #
  # This is the counterpart of {send_approval_email} for staff-initiated
  # invites.
  #
  def send_invited_email
    notification = IdealsMailer.invited(self)
    notification.deliver_now
  end

  ##
  # Sends a password reset email. Typically this would be called after
  # {create_reset_digest}.
  #
  def send_password_reset_email
    notification = IdealsMailer.password_reset(self)
    notification.deliver_now
  end

  ##
  # Sends an email to the invitee welcoming them to the system following
  # successful registration.
  #
  def send_post_registration_email
    IdealsMailer.account_registered(self).deliver_now
  end

  ##
  # @param password [String]
  # @param confirmation [String]
  #
  def update_password!(password:, confirmation:)
    update!(password: password, password_confirmation: confirmation)
    update_attribute(:reset_digest, nil)
    update_attribute(:reset_sent_at, nil)
  end


  private

  def set_lowercase_email
    self.lowercase_email = self.email.downcase
  end

  def validate_invitee_expiration
    if invitee&.expired?
      errors.add(:base, "Identity does not have a current invitation.")
    end
  end

  def validate_password_strength
    if self.password
      if self.password.length < PASSWORD_MIN_LENGTH
        errors.add(:password, "must be at least #{PASSWORD_MIN_LENGTH} characters")
      elsif self.password.gsub(/[^A-Z]/, "").length < PASSWORD_MIN_UPPERCASE_LETTERS
        errors.add(:password, "must contain at least #{PASSWORD_MIN_UPPERCASE_LETTERS} uppercase letter")
      elsif self.password.gsub(/[^a-z]/, "").length < PASSWORD_MIN_LOWERCASE_LETTERS
        errors.add(:password, "must contain at least #{PASSWORD_MIN_LOWERCASE_LETTERS} lowercase letter")
      elsif self.password.gsub(/[^\d]/, "").length < PASSWORD_MIN_NUMBERS
        errors.add(:password, "must contain at least #{PASSWORD_MIN_NUMBERS} number")
      elsif self.password.gsub(/[^#{PASSWORD_SPECIAL_CHARACTERS}]/, "").length < PASSWORD_MIN_SPECIAL_CHARACTERS
        errors.add(:password, "must contain at least #{PASSWORD_MIN_SPECIAL_CHARACTERS} special character (#{PASSWORD_SPECIAL_CHARACTERS})")
      end
    end
  end

end
