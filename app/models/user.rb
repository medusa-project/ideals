# frozen_string_literal: true

##
# Abstract class representing a user. Concrete implementations are subclasses
# using Rails single-table inheritance. (Basically this just means that their
# class name is stored in the `type` column.)
#
class User < ApplicationRecord
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  include Breadcrumb
  include Indexed

  has_many :administrators
  has_many :administering_units, through: :administrators, source: :unit
  has_many :managers
  has_many :managing_collections, through: :managers, source: :collection
  has_many :primary_administering_units, class_name: "Unit",
           inverse_of: :primary_administrator
  has_many :submitted_items, class_name: "Item", inverse_of: :submitter
  has_many :submitting_collections, through: :submitters, source: :collection
  has_and_belongs_to_many :user_groups

  validates :name, presence: true
  validates_uniqueness_of :email, scope: :type
  validates :email, presence: true, length: {maximum: 255},
            format: {with: VALID_EMAIL_REGEX}
  validates_uniqueness_of :uid, allow_blank: false

  before_save -> { email.downcase! }

  ##
  # Contains constants for all "technical" indexed fields.
  #
  class IndexFields
    CLASS         = ElasticsearchIndex::StandardFields::CLASS
    CREATED       = ElasticsearchIndex::StandardFields::CREATED
    EMAIL         = "k_email"
    ID            = ElasticsearchIndex::StandardFields::ID
    LAST_INDEXED  = ElasticsearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED = ElasticsearchIndex::StandardFields::LAST_MODIFIED
    NAME          = "t_name"
    USERNAME      = "k_username"
  end

  ##
  # @param string [String] Autocomplete text field string.
  # @return [User] Instance corresponding to the given string. May be `nil`.
  # @see to_autocomplete
  #
  def self.from_autocomplete_string(string)
    if string.present?
      # user strings may be in one of two formats: "Name (email)" or "email"
      tmp = string.scan(/\((.*)\)/).last
      email = tmp ? tmp.first : string
      return User.find_by_email(email)
    end
    nil
  end

  ##
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json
    doc = {}
    doc[IndexFields::CLASS]         = ["User", self.class.to_s]
    doc[IndexFields::CREATED]       = self.created_at.utc.iso8601
    doc[IndexFields::LAST_INDEXED]  = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED] = self.updated_at.utc.iso8601
    doc[IndexFields::EMAIL]         = self.email
    doc[IndexFields::NAME]          = self.name
    doc[IndexFields::USERNAME]      = self.username
    doc
  end

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
  # @return [String] The instance's name and/or email formatted for an
  #                  autocomplete text field.
  # @see from_autocomplete_string
  #
  def to_autocomplete
    # N.B.: changing this probably requires changing some JavaScript and
    # controller code.
    name.present? ? "#{name} (#{email})" : email
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
