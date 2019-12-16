# frozen_string_literal: true

require "open-uri"
require "json"

module User
  # This is an abstract class to represent a User
  # Class methods used because Shibboleth identities are not persistent in ideals

  class User < ApplicationRecord
    include ActiveModel::Serialization

    validates_uniqueness_of :uid, allow_blank: false
    before_save :downcase_email
    validates :name, presence: true
    validates_uniqueness_of :email, scope: :provider
    validates :email, presence: true, length: {maximum: 255},
              format: {with: VALID_EMAIL_REGEX}

    def is?(requested_role)
      role == requested_role.to_s
    end

    # Converts email to all lower-case.
    def downcase_email
      self.email = email.downcase
    end

    def self.create_or_update(email:, role: Ideals::UserRole::GUEST)

      email_string = email.to_s.strip
      raise ArgumentError, "email address required" unless email && !email_string.empty?

      raise ArgumentError, "valid email address required" unless email_string.match(URI::MailTo::EMAIL_REGEXP)

      raise ArgumentError unless Ideals::UserRole::ARRAY.include?(role)

      domain = email_string.split("@").last

      if domain == "illinois.edu"
        user = User.find_by(email: email, provider: Ideals::AuthProvider::SHIBBOLETH)
        if user
          user.role = role
        else
          create! do |user|
            user.provider = Ideals::AuthProvider::SHIBBOLETH
            user.uid = email_string
            user.email = email_string
            user.username = email_string.split("@").first
            user.name = email_string.split("@").first
            user.role = role
          end
        end
      end
      user = if domain == "illinois.edu"
        User.find_by(email: email, provider: Ideals::AuthProvider::SHIBBOLETH)
      else
        User.find_by(email: email, provider: Ideals::AuthProvider::IDENTITY)
                      end
      if user
        user.role = role
        user.save!
      elsif domain == "illinois.edu"
      end





    end

    def self.from_omniauth(_auth)
      raise "subclass responsibility"
    end

    def self.create_with_omniauth(_auth)
      raise "subclass responsibility"
    end

    def update_with_omniauth(_auth)
      raise "subclass responsibility"
    end

    def self.user_role(_email)
      raise "subclass responsibility"
    end

    def self.display_name(_email)
      raise "subclass responsibility"
    end
  end
end
