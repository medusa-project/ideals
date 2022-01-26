# frozen_string_literal: true

##
# See the documentation of {Indexed} for a detailed explanation of how indexing
# works.
#
# # Deletion
#
# Units are not normally deleted. Instead they are "buried" via {bury!}, which
# leaves behind a row in the `units` table that can facilitate display of a
# tombstone record.
#
# # Attributes
#
# * `buried`            Indicates a "near-deletion" which leaves behind only a
#                       row in the units table that facilitates display of a
#                       tombstone record. The burial is not reversible.
# * `created_at`        Managed by ActiveRecord.
# * `institution_id`    Foreign key to {Institution}.
# * `introduction`      Introduction string. May contain HTML.
# * `parent_id`         Foreign key to a parent {Unit}.
# * `rights`            Rights string.
# * `short_description` Short description string.
# * `title`             Unit title.
# * `updated_at`        Managed by ActiveRecord.
#
class Unit < ApplicationRecord
  include Breadcrumb
  include Indexed

  class IndexFields
    ADMINISTRATORS        = "i_administrator_id"
    BURIED                = "b_buried"
    CLASS                 = ElasticsearchIndex::StandardFields::CLASS
    CREATED               = ElasticsearchIndex::StandardFields::CREATED
    ID                    = ElasticsearchIndex::StandardFields::ID
    INSTITUTION_KEY       = ElasticsearchIndex::StandardFields::INSTITUTION_KEY
    INTRODUCTION          = "t_introduction"
    LAST_INDEXED          = ElasticsearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED         = ElasticsearchIndex::StandardFields::LAST_MODIFIED
    PARENT                = "i_parent_id"
    PRIMARY_ADMINISTRATOR = "i_primary_administrator_id"
    RIGHTS                = "t_rights"
    SHORT_DESCRIPTION     = "t_short_description"
    TITLE                 = "t_title"
  end

  belongs_to :institution
  belongs_to :parent, class_name: "Unit", foreign_key: "parent_id", optional: true

  has_many :administrators
  has_many :administering_users, through: :administrators,
           class_name: "User", source: :user
  has_many :administrator_groups
  has_many :administering_groups, through: :administrator_groups,
           class_name: "UserGroup", source: :user_group
  has_many :unit_collection_memberships
  has_many :collections, through: :unit_collection_memberships
  has_many :units, foreign_key: "parent_id", dependent: :restrict_with_exception
  has_one :handle
  has_one :primary_administrator_relationship, -> { where(primary: true) },
          class_name: "Administrator"
  has_one :primary_administrator, through: :primary_administrator_relationship,
          source: :user
  scope :top, -> { where(parent_id: nil) }
  scope :bottom, -> { where(children.count == 0) }

  validates :title, presence: true
  validate :validate_buried, if: -> { buried }
  validate :validate_parent, :validate_primary_administrator

  after_save :assign_handle, if: -> { handle.nil? && !IdealsImporter.instance.running? }
  after_create :create_default_collection, unless: -> { IdealsImporter.instance.running? }
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
  # @return [Enumerable<UserGroup>]
  #
  def all_administrator_groups
    groups  = Set.new
    groups += self.administering_groups
    all_parents.each do |parent|
      groups += parent.administering_groups
    end
    groups
  end

  ##
  # @return [Enumerable<Unit>] All units that are children of the instance, at
  #                            any level in the tree.
  # @see walk_tree
  #
  def all_children
    # This is much faster than walking down the tree via ActiveRecord.
    sql = "WITH RECURSIVE q AS (
        SELECT h, ARRAY[id] AS breadcrumb
        FROM units h
        WHERE id = $1
        UNION ALL
        SELECT hi, breadcrumb || id
        FROM q
        JOIN units hi
          ON hi.parent_id = (q.h).id
      )
      SELECT (q.h).id
      FROM q
      ORDER BY breadcrumb"
    values  = [self.id]
    results = ActiveRecord::Base.connection.exec_query(sql, "SQL", values)
    Unit.where("id IN (?)", results.
        select{ |row| row['id'] != self.id }.
        map{ |row| row['id'] })
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
    doc[IndexFields::BURIED]                = self.buried
    doc[IndexFields::CLASS]                 = self.class.to_s
    doc[IndexFields::CREATED]               = self.created_at.utc.iso8601
    doc[IndexFields::INSTITUTION_KEY]       = self.institution&.key
    doc[IndexFields::INTRODUCTION]          = self.introduction
    doc[IndexFields::LAST_INDEXED]          = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED]         = self.updated_at.utc.iso8601
    doc[IndexFields::PARENT]                = self.parent_id
    doc[IndexFields::PRIMARY_ADMINISTRATOR] = self.primary_administrator&.id
    doc[IndexFields::RIGHTS]                = self.rights
    doc[IndexFields::SHORT_DESCRIPTION]     = self.short_description
    doc[IndexFields::TITLE]                 = self.title
    doc
  end

  ##
  # Renders an instance almost totally deleted, leaving behind a tombstone
  # record.
  #
  # @raises [RuntimeError] if the instance contains any dependent collections.
  #
  def bury!
    update!(buried: true)
  end

  ##
  # @return [Boolean] Whether the instance if a child of another {Unit}.
  #
  def child?
    self.parent_id.present?
  end

  ##
  # Creates a new {Collection} and assigns the instance as its primary unit.
  #
  # N.B.: This method doesn't work properly during an
  # {IdealsImporter#running? import}. This is because units are imported before
  # collections and imported IDs are fixed, so any collection IDs created here
  # would get overwritten in the subsequent collection-import step. The
  # importer instead has to invoke this method on all units **after** all
  # collections have been imported.
  #
  # @return [Collection]
  #
  def create_default_collection
    return if self.unit_collection_memberships.where(unit_default: true).count > 0
    transaction do
      collection = Collection.create!(title:       "Default collection for #{self.title}",
                                      description: "This collection was "\
                                      "created automatically along with its parent unit.")
      self.unit_collection_memberships.build(unit:         self,
                                             collection:   collection,
                                             primary:      true,
                                             unit_default: true).save!
      collection
    end
  end

  ##
  # @return [Collection]
  #
  def default_collection
    self.unit_collection_memberships.where(unit_default: true).limit(1).first&.collection
  end

  ##
  # @param start_time [Time]          Optional beginning of a time range.
  # @param end_time [Time]            Optional end of a time range.
  # @param include_children [Boolean] Whether to include child units in the
  #                                   count.
  # @return [Integer] Total download count of all bitstreams attached to all
  #                   items in all of the unit's collections.
  #
  def download_count(start_time: nil, end_time: nil, include_children: true)
    count = 0
    if include_children
      self.all_children.each do |child|
        count += child.download_count(start_time:       start_time,
                                      end_time:         end_time,
                                      include_children: false)
      end
    end
    self.collections.map{ |c| c.download_count(start_time:       start_time,
                                               end_time:         end_time,
                                               include_children: false) }.sum + count
  end

  ##
  # @param start_time [Time]   Optional beginning of a time range.
  # @param end_time [Time]     Optional end of a time range.
  # @return [Enumerable<Hash>] Enumerable of hashes with `month` and `dl_count`
  #                            keys.
  #
  def download_count_by_month(start_time: nil, end_time: nil)
    start_time = Event.all.order(:happened_at).limit(1).pluck(:happened_at).first unless start_time
    end_time   = Time.now unless end_time

    sql = "WITH RECURSIVE q AS (
        SELECT u
        FROM units u
        WHERE id = $1
        UNION ALL
        SELECT ui
        FROM q
        JOIN units ui ON ui.parent_id = (q.u).id
    )
    SELECT mon.month, coalesce(e.count, 0) AS dl_count
    FROM generate_series('#{start_time.strftime("%Y-%m-%d")}'::timestamp,
                         '#{end_time.strftime("%Y-%m-%d")}'::timestamp, interval '1 month') AS mon(month)
        LEFT JOIN (
            SELECT date_trunc('Month', e.happened_at) as month,
                   COUNT(e.id) AS count
            FROM events e
                LEFT JOIN bitstreams b on e.bitstream_id = b.id
                LEFT JOIN items i ON b.item_id = i.id
                LEFT JOIN collection_item_memberships cim ON cim.item_id = i.id
                LEFT JOIN unit_collection_memberships ucm ON ucm.collection_id = cim.collection_id
                LEFT JOIN q ON ucm.unit_id IN (SELECT (q.u).id FROM q)
            WHERE (q.u).id = $1
                AND e.event_type = $2
                AND e.happened_at >= $3
                AND e.happened_at <= $4
            GROUP BY month) e ON mon.month = e.month
    ORDER BY mon.month;"
    values = [self.id, Event::Type::DOWNLOAD, start_time, end_time]
    self.class.connection.exec_query(sql, "SQL", values)
  end

  ##
  # N.B.: Only items with ascribed titles are included in results.
  #
  # @param offset [Integer]    SQL OFFSET clause.
  # @param limit [Integer]     SQL LIMIT clause.
  # @param start_time [Time]   Optional beginning of a time range.
  # @param end_time [Time]     Optional end of a time range.
  # @return [Enumerable<Hash>] Enumerable of hashes representing items and
  #                            their corresponding download counts.
  #
  def item_download_counts(offset: 0, limit: 0,
                           start_time: nil, end_time: nil)
    sql = StringIO.new
    sql << "WITH RECURSIVE q AS (
        SELECT u
        FROM units u
        WHERE id = $1
        UNION ALL
        SELECT ui
        FROM q
        JOIN units ui ON ui.parent_id = (q.u).id
    )
    SELECT *
        FROM (
            SELECT DISTINCT ON (i.id) i.id AS id,
                ae.string AS title,
                COUNT(e.id) AS dl_count
            FROM items i
                LEFT JOIN ascribed_elements ae ON ae.item_id = i.id
                LEFT JOIN registered_elements re ON re.id = ae.registered_element_id
                LEFT JOIN bitstreams b ON b.item_id = i.id
                LEFT JOIN events e ON e.bitstream_id = b.id
                LEFT JOIN collection_item_memberships cim ON cim.item_id = i.id
                LEFT JOIN unit_collection_memberships ucm ON ucm.collection_id = cim.collection_id
             LEFT JOIN q ON ucm.unit_id IN (SELECT (q.u).id FROM q)
             WHERE (q.u).id = $1
                AND re.name = $2
                AND e.event_type = $3 "
    sql <<      "AND e.happened_at >= $4 " if start_time
    sql <<      "AND e.happened_at <= #{start_time ? "$5" : "$4"} " if end_time
    sql <<  "GROUP BY i.id, ae.string"
    sql << ") items_with_dl_count "
    sql << "ORDER BY items_with_dl_count.dl_count DESC "
    sql << "OFFSET #{offset} " if offset > 0
    sql << "LIMIT #{limit} " if limit > 0

    values = [
      self.id,
      ::Configuration.instance.elements[:title],
      Event::Type::DOWNLOAD
    ]
    values << start_time if start_time
    values << end_time if end_time
    self.class.connection.exec_query(sql.string, 'SQL', values)
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

  ##
  # @param start_time [Time]          Optional beginning of a time range.
  # @param end_time [Time]            Optional end of a time range.
  # @param include_children [Boolean] Whether to include child units in the
  #                                   count.
  # @return [Integer] Total number of submitted items in all of the unit's
  #                   collections.
  #
  def submitted_item_count(start_time: nil,
                           end_time: nil,
                           include_children: true)
    count = 0
    if include_children
      self.all_children.each do |child|
        count += child.submitted_item_count(start_time:       start_time,
                                            end_time:         end_time,
                                            include_children: false)
      end
    end
    self.collections.map{ |c| c.submitted_item_count(start_time:       start_time,
                                                     end_time:         end_time,
                                                     include_children: false) }.sum + count
  end

  ##
  # @param start_time [Time]   Optional beginning of a time range.
  # @param end_time [Time]     Optional end of a time range.
  # @return [Enumerable<Hash>] Enumerable of hashes with `month` and `dl_count`
  #                            keys.
  #
  def submitted_item_count_by_month(start_time: nil, end_time: nil)
    start_time = Event.all.order(:happened_at).limit(1).pluck(:happened_at).first unless start_time
    end_time   = Time.now unless end_time

    sql = "WITH RECURSIVE q AS (
        SELECT u
        FROM units u
        WHERE id = $1
        UNION ALL
        SELECT ui
        FROM q
        JOIN units ui ON ui.parent_id = (q.u).id
    )
    SELECT mon.month, coalesce(e.count, 0) AS count
    FROM generate_series('#{start_time.strftime("%Y-%m-%d")}'::timestamp,
                         '#{end_time.strftime("%Y-%m-%d")}'::timestamp, interval '1 month') AS mon(month)
        LEFT JOIN (
            SELECT date_trunc('Month', e.happened_at) as month,
                   COUNT(e.id) AS count
            FROM events e
                LEFT JOIN items i ON e.item_id = i.id
                LEFT JOIN collection_item_memberships cim ON cim.item_id = i.id
                LEFT JOIN unit_collection_memberships ucm ON ucm.collection_id = cim.collection_id
                LEFT JOIN q ON ucm.unit_id IN (SELECT (q.u).id FROM q)
            WHERE (q.u).id = $1
                AND e.event_type = $2
                AND e.happened_at >= $3
                AND e.happened_at <= $4
            GROUP BY month) e ON mon.month = e.month
    ORDER BY mon.month;"
    values = [self.id, Event::Type::CREATE, start_time, end_time]
    self.class.connection.exec_query(sql, "SQL", values)
  end

  ##
  # @param include_children [Boolean] Whether to include child units in the
  #                                   count.
  # @return [Integer] Total number of submitted items in all of the unit's
  #                   collections.
  #
  def submitting_item_count(include_children: true)
    count = 0
    if include_children
      self.all_children.each do |child|
        count += child.submitting_item_count(include_children: false)
      end
    end
    self.collections.map{ |c| c.submitting_item_count(include_children: false) }.sum + count
  end


  private

  ##
  # @return [void]
  #
  def assign_handle
    if self.handle.nil? && !IdealsImporter.instance.running?
      self.handle = Handle.create!(unit: self)
    end
  end

  ##
  # Ensures that a buried unit does not contain any collections.
  #
  def validate_buried
    if buried
      if units.where.not(buried: true).count > 0
        errors.add(:base, "This unit cannot be deleted, as it contains at "\
                          "least one child unit.")
      elsif collections.where.not(buried: true).count > 0
        errors.add(:base, "This unit cannot be deleted, as it contains at "\
                          "least one collection.")
      end
    end
  end

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
