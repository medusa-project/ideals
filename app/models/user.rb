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
  has_many :managing_collections, through: :managers, source: :collection
  has_many :primary_administering_units, class_name: "Unit",
           inverse_of: :primary_administrator
  has_many :submitting_collections, through: :submitters, source: :collection

  validates :name, presence: true
  validates_uniqueness_of :email, scope: :type
  validates :email, presence: true, length: {maximum: 255},
            format: {with: VALID_EMAIL_REGEX}
  validates_uniqueness_of :uid, allow_blank: false

  before_save -> { email.downcase! }

  ##
  # @param collection [Collection]
  # @return [Boolean] Whether the instance is an effective manager of the given
  #                   collection, either directly or as a unit or system
  #                   administrator.
  # @see #manager?
  #
  def effective_manager?(collection)
    # check for sysadmin
    return true if sysadmin?
    # check for unit admin
    collection.units.each do |unit|
      return true if unit_admin?(unit)
    end
    # check for collection manager
    manager?(collection)
  end

  ##
  # For compatibility with breadcrumbs.
  #
  def label
    name
  end

  ##
  # @param collection [Collection]
  # @return [Boolean] Whether the instance is a direct manager of the given
  #                   collection.
  # @see #effective_manager?
  #
  def manager?(collection)
    collection.managers.where(user_id: self.id).count > 0
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
