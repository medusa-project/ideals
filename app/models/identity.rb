# frozen_string_literal: true

class Identity < OmniAuth::Identity::Models::ActiveRecord

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  attr_accessor :activation_token, :reset_token
  before_create :set_invitee
  before_create :create_activation_digest
  after_create :send_activation_email
  before_destroy :destroy_user
  validates :name, presence: true
  validates :email, presence: true, length: {maximum: 255},
            format: {with: VALID_EMAIL_REGEX},
            uniqueness: {case_sensitive: false}
  has_secure_password
  validates :password, presence: true, length: {minimum: 6}
  validate :invited

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

  # Returns the hash digest of the given string.
  def self.digest(string)
    cost = if ActiveModel::SecurePassword.min_cost
             BCrypt::Engine::MIN_COST
           else
             BCrypt::Engine.cost
           end
    BCrypt::Password.create(string, cost: cost)
  end

  # Returns a random token.
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  # Returns true if the given token matches the digest.
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?

    BCrypt::Password.new(digest).is_password?(token)
  end

  def invited
    set_invitee
    errors.add(:base, "Registered identity must have current invitation.") unless [nil, ""].exclude?(invitee_id)
  end

  def activation_url
    "#{::Configuration.instance.website[:base_url]}/account_activations/#{activation_token}/edit?email=#{CGI.escape(email)}"
  end

  def password_reset_url
    "#{::Configuration.instance.website[:base_url]}/password_reset/#{reset_token}/edit?email=#{CGI.escape(email)}"
  end

  def send_activation_email
    notification = IdealsMailer.account_activation(self)
    notification.deliver_now
  end

  # Sends password reset email.
  def send_password_reset_email
    notification = IdealsMailer.password_reset(self)
    notification.deliver_now
  end

  # Creates and assigns the activation token and digest.
  def create_activation_digest
    self.activation_token = Identity.new_token
    self.activation_digest = Identity.digest(activation_token)
  end

  # Sets the password reset attributes.
  def create_reset_digest
    reset_token = Identity.new_token
    update_attribute(:reset_digest, Identity.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  private

  # Converts email to all lower-case.
  def downcase_email
    self.email = email.downcase
  end

  def destroy_user
    user = IdentityUser.find_by(email: email)
    user&.destroy!
  end

  def set_invitee
    @invitee = Invitee.find_by(email: email)
    self.invitee_id = @invitee.id if @invitee&.expires_at && @invitee.expires_at > Time.zone.now
  end
end
