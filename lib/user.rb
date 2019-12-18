# frozen_string_literal: true

require "open-uri"
require "json"

module User
  # This is an abstract class to represent a User
  # Class methods used because Shibboleth identity details are not persistent in ideals

  class User < ApplicationRecord
    include ActiveModel::Serialization

    has_many :assignments
    has_many :roles, through: :assignments

    validates_uniqueness_of :uid, allow_blank: false
    before_save :downcase_email
    validates :name, presence: true
    validates_uniqueness_of :email, scope: :provider
    validates :email, presence: true, length: {maximum: 255},
              format: {with: VALID_EMAIL_REGEX}

    def role?(role)
      roles.any? {|r| r.name.underscore.to_sym == role }
    end

    def sysadmin?
      role? :sysadmin
    end

    # Converts email to all lower-case.
    def downcase_email
      self.email = email.downcase
    end

    def self.no_omniauth(email, provider)
      User.create_no_omniauth(email, provider) unless User.exists?(email: email, provider: provider)
      User.find_by(email: email, provider: provider)
    end

    def self.create_no_omniauth(email, provider)
      create! do |user|
        user.provider = provider
        user.uid = email
        user.email = email
        user.username = email
        user.name = email
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

    def self.display_name(_email)
      raise "subclass responsibility"
    end
  end
end
