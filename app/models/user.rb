# frozen_string_literal: true

##
# Abstract class representing a user. Concrete implementations are subclasses
# using Rails single-table inheritance. (Basically this just means that their
# class name is stored in the `type` column.)
#
class User < ApplicationRecord
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  include Breadcrumb

  has_many :administrators
  has_many :administering_units, through: :administrators, source: :unit
  has_many :assignments
  has_many :managing_collections, through: :managers, source: :collection
  has_many :primary_administering_units, class_name: "Unit",
           inverse_of: :primary_administrator
  has_many :roles, through: :assignments
  has_many :submitting_collections, through: :submitters, source: :collection

  validates :name, presence: true
  validates_uniqueness_of :email, scope: :type
  validates :email, presence: true, length: {maximum: 255},
            format: {with: VALID_EMAIL_REGEX}
  validates_uniqueness_of :uid, allow_blank: false

  before_save -> { email.downcase! }

  ##
  # For compatibility with breadcrumbs.
  #
  def label
    name
  end

  ##
  # @param collection [Collection]
  # @return [Boolean] Whether the instance is a manager of the given collection.
  #
  def manager?(collection)
    collection.managers.where(user_id: self.id).count > 0
  end

  ##
  # @param role [Symbol] Role name. TODO: accept a Role
  # @return [Boolean] Whether the instance is a member of the given role.
  #
  def role?(role)
    roles.any? {|r| r.name.underscore.to_sym == role }
  end

  ##
  # @return [Boolean] Whether the instance is a member of the `sysadmin` role.
  #
  def sysadmin?
    role? :sysadmin
  end

  ##
  # @param unit [Unit]
  # @return [Boolean] Whether the instance is an administrator of the given
  #                   unit.
  #
  def unit_admin?(unit)
    unit.administrators.where(user_id: self.id).count > 0
  end
end
