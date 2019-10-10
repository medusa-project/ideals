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
    validates :name,  presence: true
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

    def group
      if provider == Ideals::AuthProvider::SHIBBOLETH
        provider
      elsif provider == Ideals::AuthProvider::IDENTITY
        invitee = Invitee.find_by(email: email)
        raise("no invitation found for identity: #{email}") unless invitee

        invitee.group
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
