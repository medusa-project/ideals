# frozen_string_literal: true

##
# See the documentation of {Indexed} for a detailed explanation of how indexing
# works.
#
class Unit < ApplicationRecord
  include Breadcrumb
  include Indexed

  class IndexFields
    ADMINISTRATORS        = "i_administrator_id"
    CLASS                 = ElasticsearchIndex::StandardFields::CLASS
    CREATED               = ElasticsearchIndex::StandardFields::CREATED
    ID                    = ElasticsearchIndex::StandardFields::ID
    LAST_INDEXED          = ElasticsearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED         = ElasticsearchIndex::StandardFields::LAST_MODIFIED
    PARENT                = "i_parent_id"
    PRIMARY_ADMINISTRATOR = "i_primary_administrator_id"
    TITLE                 = "t_title"
  end

  has_many :administrators
  has_many :administering_users, through: :administrators,
           class_name: "User", source: :user
  has_and_belongs_to_many :collections
  belongs_to :parent, class_name: "Unit", foreign_key: "parent_id", optional: true
  has_one :primary_administrator_relationship, -> { where(primary: true) },
          class_name: "Administrator"
  has_one :primary_administrator, through: :primary_administrator_relationship,
          source: :user
  scope :top, -> { where(parent_id: nil) }
  scope :bottom, -> { where(children.count == 0) }
  has_many :units, foreign_key: "parent_id", dependent: :restrict_with_exception

  validates :title, presence: true
  validate :validate_parent, :validate_primary_administrator

  before_destroy :validate_empty

  breadcrumbs parent: :parent, label: :title

  ##
  # @return [Enumerable<User>]
  #
  def all_administrators
    users = Set.new
    users += self.administering_users
    all_parents.each do |parent|
      users += parent.administering_users
    end
    users
  end

  ##
  # @return [Enumerable<Unit>] All units that are children of the instance, at
  #                            any level in the tree.
  # @see walk_tree
  #
  def all_children
    # This is much faster than walking down the tree via ActiveRecord.
    sql = "WITH RECURSIVE q AS (
        SELECT h, 1 AS level, ARRAY[id] AS breadcrumb
        FROM units h
        WHERE id = $1
        UNION ALL
        SELECT hi, q.level + 1 AS level, breadcrumb || id
        FROM q
        JOIN units hi
          ON hi.parent_id = (q.h).id
      )
      SELECT (q.h).id
      FROM q
      ORDER BY breadcrumb"
    values = [[ nil, self.id ]]

    results = ActiveRecord::Base.connection.exec_query(sql, "SQL", values)
    Unit.where("id IN (?)", results.
        select{ |row| row['id'] != self.id }.
        map{ |row| row['id'] })
  end

  ##
  # @return [Enumerable<Collection>]
  #
  def all_collections
    self.collections + Collection.where(primary_unit: self)
  end

  ##
  # @return [Enumerable<Unit>] All parents in order from closest to farthest.
  #
  def all_parents
    parents = []
    p = self.parent
    while p
      parents << p
      p = p.parent
    end
    parents
  end

  ##
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json
    doc = {}
    doc[IndexFields::ADMINISTRATORS]        = self.administrators.map(&:user_id)
    doc[IndexFields::CLASS]                 = self.class.to_s
    doc[IndexFields::CREATED]               = self.created_at.utc.iso8601
    doc[IndexFields::LAST_INDEXED]          = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED]         = self.updated_at.utc.iso8601
    doc[IndexFields::PARENT]                = self.parent_id
    doc[IndexFields::PRIMARY_ADMINISTRATOR] = self.primary_administrator&.id
    doc[IndexFields::TITLE]                 = self.title
    doc
  end

  ##
  # @return [Boolean] Whether the instance if a child of another {Unit}.
  #
  def child?
    self.parent_id.present?
  end

  def label
    title
  end

  ##
  # Sets the primary administrator. The previous primary administrator is not
  # removed from {administrators}.
  #
  # @param user [User] Primary administrator to set.
  #
  def primary_administrator=(user)
    self.administrators.update_all(primary: false)
    if user
      admin = self.administrators.where(user: user).limit(1).first
      if admin
        admin.update!(primary: true)
      else
        self.administrators.build(user: user, primary: true).save!
      end
    end
  end

  ##
  # @return [Unit] The root parent unit, which may the instance itself if it is
  #                a root unit.
  #
  def root_parent
    self.parent ? all_parents.last : self
  end

  private

  ##
  # Ensures that the unit cannot be destroyed unless it is empty.
  #
  def validate_empty
    if self.units.count > 0
      errors.add(:units, "must not exist in order for a unit to be deleted")
      throw(:abort)
    elsif self.collections.count > 0
      errors.add(:collections, "must not exist in order for a unit to be deleted")
      throw(:abort)
    end
  end

  ##
  # Ensures that {parent_id} is not set to the instance ID nor any of the IDs
  # of its children.
  #
  def validate_parent
    if self.parent_id.present?
      if self.id.present? && self.parent_id == self.id
        errors.add(:parent_id, "cannot be set to the same unit")
      elsif all_children.map(&:id).include?(self.parent_id)
        errors.add(:parent_id, "cannot be set to a child unit")
      end
    end
  end

  ##
  # Ensures that only top-level units can have a primary administrator
  # assigned.
  #
  def validate_primary_administrator
    if self.parent_id.present? and self.primary_administrator.present?
      errors.add(:primary_administrator, "cannot be set on child units")
    end
  end

end
