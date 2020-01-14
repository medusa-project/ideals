# frozen_string_literal: true

class Identity < OmniAuth::Identity::Models::ActiveRecord
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

  # Returns true if the given token matches the digest.
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?

    BCrypt::Password.new(digest).is_password?(token)
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

  def invited
    set_invitee
    errors.add(:base, "Registered identity must have current invitation.") unless [nil, ""].exclude?(invitee_id)
  end

  def activation_url
    "#{::Configuration.instance.root_url_text}/account_activations/#{activation_token}/edit?email=#{CGI.escape(email)}"
  end

  def password_reset_url
    "#{::Configuration.instance.root_url_text}/password_reset/#{reset_token}/edit?email=#{CGI.escape(email)}"
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
    user = User::Identity.find_by(email: email)
    user&.destroy!
  end

  def set_invitee
    @invitee = Invitee.find_by(email: email)
    self.invitee_id = @invitee.id if @invitee&.expires_at && @invitee.expires_at > Time.zone.now
  end
end
