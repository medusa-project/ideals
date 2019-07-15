require 'open-uri'
require 'json'

module User

  # This is an abstract class to represent a User
  # Class methods used because Shibboleth identities are not persistent in ideals

  class User < ActiveRecord::Base
    include ActiveModel::Serialization

    validates_uniqueness_of :uid, allow_blank: false
    before_save :downcase_email
    validates :name,  presence: true
    validates :email, presence: true, length: { maximum: 255 },
              format: { with: VALID_EMAIL_REGEX },
              uniqueness: { case_sensitive: false }

    def is? (requested_role)
      self.role == requested_role.to_s
    end

    # Converts email to all lower-case.
    def downcase_email
      self.email = email.downcase
    end

    def group
      if self.provider == 'shibboleth'
        self.provider
      elsif self.provider == 'identity'
        invitee = Invitee.find_by_email(self.email)
        if invitee
          invitee.group
        else
          raise("no invitation found for identity: #{self.email}")
        end
      end
    end

    def self.from_omniauth(auth)
      raise "subclass responsibility"
    end

    def self.create_with_omniauth(auth)
      raise "subclass responsibility"
    end

    def update_with_omniauth(auth)
      raise "subclass responsibility"
    end

    def self.user_role(email)
      raise "subclass responsibility"
    end

    def self.can_deposit(email)
      raise "subclass responsibility"
    end

    def self.display_name(email)
      raise "subclass responsibility"
    end

  end

end