# frozen_string_literal: true

##
# Local user identity, which hooks into OmniAuth's authentication system. This
# is more-or-less an OmniAuth-compatible surrogate of an {IdentityUser} used
# for users whose credentials are stored locally, i.e. users without a NetID.
#
# @see https://github.com/omniauth/omniauth-identity
#
class Identity < OmniAuth::Identity::Models::ActiveRecord

  attr_accessor :activation_token, :reset_token

  before_create :set_invitee
  before_create :create_activation_digest
  after_create :send_activation_email, unless: -> { Rails.env.test? }

  validates :email, presence: true, length: {maximum: 255},
            format: {with: StringUtils::EMAIL_REGEX},
            uniqueness: {case_sensitive: false}
  validates :name, presence: true
  validates :password, presence: true, length: {minimum: 6}
  validate :validate_invited, on: :create

  has_secure_password

  ##
  # Creates a counterpart for the given user. If one already exists, it is
  # updated with the given password.
  #
  # @param user [IdentityUser]
  # @param password [String]
  # @return [Identity]
  #
  def self.create_for_user(user, password)
    invitee = Invitee.find_by_email(user.email) ||
        Invitee.create!(email: user.email,
                        approval_state: ApprovalState::APPROVED)
    invitee.expires_at = Time.zone.now + 1.years
    invitee.save!

    identity           = find_or_create_by(email: user.email)
    salt               = BCrypt::Engine.generate_salt
    encrypted_password = BCrypt::Engine.hash_secret(password, salt)
    identity.update!(name: user.name,
                     password: password,
                     password_confirmation: password,
                     password_digest: encrypted_password,
                     activated: true,
                     activated_at: Time.zone.now)
    identity
  end

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
  # @param email [String] Email address.
  # @return [Boolean] Whether the given email address is related to the UofI.
  #
  def self.uofi?(email)
    domain = email.downcase.split("@").last
    ::Configuration.instance.uofi_email_domains.include?(domain)
  end

  # Returns true if the given token matches the digest.
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?

    BCrypt::Password.new(digest).is_password?(token)
  end

  ##
  # @return [String]
  #
  def activation_url
    "#{::Configuration.instance.website[:base_url]}/account_activations/#{activation_token}/edit?email=#{CGI.escape(email)}"
  end

  # Creates and assigns the activation token and digest.
  def create_activation_digest
    self.activation_token = Identity.new_token
    self.activation_digest = Identity.digest(activation_token)
  end

  # Sets the password reset attributes.
  def create_reset_digest
    self.reset_token = Identity.new_token
    update_attribute(:reset_digest, Identity.digest(self.reset_token))
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
    base_url = ::Configuration.instance.website[:base_url].chomp("/")
    "#{base_url}/identities/#{self.id}/reset-password?token=#{self.reset_token}"
  end

  def send_activation_email
    notification = IdealsMailer.account_activation(self)
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
  # @param password [String]
  # @param confirmation [String]
  #
  def update_password!(password:, confirmation:)
    update!(password: password, password_confirmation: confirmation)
    update_attribute(:reset_digest, nil)
    update_attribute(:reset_sent_at, nil)
  end

  private

  def set_invitee
    @invitee = Invitee.find_by(email: email)
    self.invitee_id = @invitee.id if @invitee&.expires_at && @invitee.expires_at > Time.zone.now
  end

  def validate_invited
    set_invitee
    unless [nil, ""].exclude?(invitee_id)
      errors.add(:base, "Registered identity does not have a current invitation.")
    end
  end

end
