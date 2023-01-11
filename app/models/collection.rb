##
# A collection is a container for {Item}s. It resides within a {Unit}. It
# supports a one-to-many parent-children relationship with itself.
#
# # Deletion
#
# Collections are not normally deleted. Instead they are "buried" via {bury!},
# which leaves behind a row in the `collections` table that can facilitate
# display of a tombstone record.
#
# # Indexing
#
# See the documentation of [Indexed] for a detailed explanation of how indexing
# works.
#
# # Attributes
#
# * `buried`                Indicates a "near-deletion" which leaves behind
#                           only a row in the table to facilitate display of a
#                           tombstone record. The burial is not reversible.
# * `created_at`            Managed by ActiveRecord.
# * `description`           Full description string. See {short_description}.
# * `institution_id`        Foreign key to {Institution}. A collection's owning
#                           institution is the same as that of its
#                           {effective_primary_unit effective primary unit},
#                           but there is an ActiveRecord callback that creates
#                           a corresponding handle before this relationship is
#                           established. The rest of the time, this attribute is
#                           just a shortcut to avoid having to navigate the
#                           {unit} relationship.
# * `introduction`          Introduction string. May contain HTML.
# * `metadata_profile_id`   Foreign key to {MetadataProfile}. Instances without
#                           this set will fall back to the primary unit's
#                           {MetadataProfile} and then to the
#                           {Institution#default_metadata_profile owning
#                           institution's metadata profile}. In most cases,
#                           {effective_metadata_profile} should be used instead
#                           of accessing this directly.
# * `parent_id`             Foreign key to the parent {Collection}.
# * `provenance`            Provenance string.
# * `rights`                Rights string.
# * `short_description`     Short description string. See {description}.
# * `submission_profile_id` Foreign key to {SubmissionProfile}. Instances
#                           without this set should fall back to the
#                           {Institution#default_submission_profile owning
#                           institution's default submission profile}. In most
#                           cases, {effective_submission_profile} should be
#                           used instead of accessing this directly.
# * `submissions_reviewed`  If true, items submitted to the collection are
#                           subject to administrator review. Otherwise, they
#                           are immediately approved.
# * `title`                 Title.
# * `updated_at`            Managed by ActiveRecord.
#
# # Relationships
#
# * `collections`         References zero-to-many sub-{Collection}s.
# * `elements`            References zero-to-many {AscribedElement}s used to
#                         describe an instance.
# * `items`               References all {Item}s contained within the instance.
# * `managers`            References the {Manager}s that are allowed to manage
#                         the instance. This does not include all "effective"
#                         managers, such as administrators of owning units or
#                         system administrators; see
#                         {User#effective_manager()?}.
# * `managing_users`      More useful alternative to {managers} that returns
#                         {User}s instead.
# * `metadata_profile`    References the {MetadataProfile} directly assigned
#                         to the instance, if any (see the documentation of the
#                         `metadata_profile_id` attribute).
# * `parent`              References a parent {Collection}.
# * `submission_profile`  References the {SubmissionProfile} directly assigned
#                         to the instance, if any (see the documentation of the
#                         `submission_profile_id` attribute).
# * `submitters`          References all {Submitter}s who are allowed to submit
#                         {Item}s into the instance.
# * `submitting_users`    More useful alternative to {submitters} that returns
#                         {User}s instead.
# * `units`               References all units to which the instance directly
#                         belongs.
#
class Collection < ApplicationRecord

  include Breadcrumb
  include Indexed
  include Handled

  class IndexFields
    BURIED            = "b_buried"
    CLASS             = OpenSearchIndex::StandardFields::CLASS
    CREATED           = OpenSearchIndex::StandardFields::CREATED
    DESCRIPTION       = "t_description"
    HANDLE            = "k_handle"
    ID                = OpenSearchIndex::StandardFields::ID
    INSTITUTION_KEY   = OpenSearchIndex::StandardFields::INSTITUTION_KEY
    INSTITUTION_NAME  = OpenSearchIndex::StandardFields::INSTITUTION_NAME
    INTRODUCTION      = "t_introduction"
    LAST_INDEXED      = OpenSearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED     = OpenSearchIndex::StandardFields::LAST_MODIFIED
    MANAGERS          = "i_manager_id"
    PARENT            = "i_parent_id"
    PRIMARY_UNIT      = "i_primary_unit_id"
    PROVENANCE        = "t_provenance"
    RIGHTS            = "t_rights"
    SHORT_DESCRIPTION = "t_short_description"
    SUBMITTERS        = "i_submitter_id"
    TITLE             = "t_title"
    UNIT_DEFAULT      = "b_unit_default"
    UNIT_TITLES       = "t_unit_titles"
    UNITS             = "i_units"
  end

  has_many :collections, foreign_key: "parent_id",
           dependent: :restrict_with_exception
  has_one :handle
  has_many :collection_item_memberships
  belongs_to :institution
  has_many :imports
  has_many :items, through: :collection_item_memberships
  belongs_to :metadata_profile, inverse_of: :collections, optional: true
  has_many :manager_groups
  has_many :managing_groups, through: :manager_groups,
           class_name: "UserGroup", source: :user_group
  has_many :managers
  has_many :managing_users, through: :managers,
           class_name: "User", source: :user
  belongs_to :parent, class_name: "Collection",
             foreign_key: "parent_id", optional: true
  has_one :primary_unit_membership, -> { where(primary: true) },
          class_name: "UnitCollectionMembership"
  has_one :primary_unit, through: :primary_unit_membership,
          class_name: "Unit", source: :unit
  belongs_to :submission_profile, inverse_of: :collections, optional: true
  has_many :submitter_groups
  has_many :submitting_groups, through: :submitter_groups,
           class_name: "UserGroup", source: :user_group
  has_many :submitters
  has_many :submitting_users, through: :submitters,
           class_name: "User", source: :user
  has_many :unit_collection_memberships
  has_many :units, through: :unit_collection_memberships

  validate :validate_parent
  validate :validate_primary_unit
  validate :validate_buried, if: -> { buried }
  validate :validate_exhumed, if: -> { !buried }

  before_destroy :validate_empty

  ##
  # @return [Enumerable<Collection>] All collections that are children of the
  #                                  instance, at any level in the tree.
  # @see walk_tree
  #
  def all_children
    # This is much faster than walking down the tree via ActiveRecord.
    sql = "WITH RECURSIVE q AS (
        SELECT h, 1 AS level, ARRAY[id] AS breadcrumb
        FROM collections h
        WHERE id = $1
        UNION ALL
        SELECT hi, q.level + 1 AS level, breadcrumb || id
        FROM q
        JOIN collections hi
          ON hi.parent_id = (q.h).id
      )
      SELECT (q.h).id
      FROM q
      ORDER BY breadcrumb"
    values  = [self.id]
    results = ActiveRecord::Base.connection.exec_query(sql, "SQL", values)
    Collection.where("id IN (?)", results.
        select{ |row| row['id'] != self.id }.
        map{ |row| row['id'] })
  end

  ##
  # @return [Enumerable<UserGroup>]
  #
  def all_managing_groups
    groups  = Set.new
    groups += self.managing_groups
    all_parents.each do |parent|
      groups += parent.managing_groups
    end
    groups
  end

  ##
  # @return [Enumerable<Collection>] All parents in order from closest to
  #                                  farthest.
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
  # @return [Enumerable<UserGroup>]
  #
  def all_submitting_groups
    groups  = Set.new
    groups += self.submitting_groups
    all_parents.each do |parent|
      groups += parent.submitting_groups
    end
    groups
  end

  ##
  # @return [Enumerable<User>]
  #
  def all_unit_administrators
    bucket = Set.new
    units.each do |unit|
      bucket += unit.all_administrators
    end
    bucket
  end

  ##
  # @return [Enumerable<Unit>] All owning units, including their parents.
  #
  def all_units
    bucket = Set.new
    self.units.each do |unit|
      bucket << unit
      bucket += unit.all_parents
    end
    bucket
  end

  ##
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json
    doc = {}
    units                               = self.units
    doc[IndexFields::BURIED]            = self.buried
    doc[IndexFields::CLASS]             = self.class.to_s
    doc[IndexFields::CREATED]           = self.created_at.utc.iso8601
    doc[IndexFields::DESCRIPTION]       = self.description
    doc[IndexFields::HANDLE]            = self.handle&.handle
    doc[IndexFields::INSTITUTION_KEY]   = self.institution&.key
    doc[IndexFields::INSTITUTION_NAME]  = self.institution&.name
    doc[IndexFields::INTRODUCTION]      = self.introduction
    doc[IndexFields::LAST_INDEXED]      = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED]     = self.updated_at.utc.iso8601
    doc[IndexFields::PARENT]            = self.parent_id
    doc[IndexFields::PRIMARY_UNIT]      = self.primary_unit&.id
    doc[IndexFields::PROVENANCE]        = self.provenance
    doc[IndexFields::RIGHTS]            = self.rights
    doc[IndexFields::SHORT_DESCRIPTION] = self.short_description
    doc[IndexFields::TITLE]             = self.title
    doc[IndexFields::UNIT_DEFAULT]      = self.unit_default?
    doc[IndexFields::UNIT_TITLES]       = units.map(&:title)
    doc[IndexFields::UNITS]             = self.unit_ids
    doc
  end

  def breadcrumb_label
    self.title
  end

  def breadcrumb_parent
    self.parent || self.primary_unit
  end

  ##
  # Renders an instance almost totally deleted, leaving behind a tombstone
  # record.
  #
  # @raises [RuntimeError] if the instance contains any dependent items or
  #         collections.
  # @see exhume!
  #
  def bury!
    update!(buried: true) unless buried
  end

  ##
  # Compiles monthly download counts for a given time span by querying the
  # `events` table.
  #
  # Note that {MonthlyCollectionItemDownloadCount#for_collection} uses a
  # different technique--querying the monthly collection download count
  # reporting table--that is much faster.
  #
  # @param start_time [Time]   Optional beginning of a time range.
  # @param end_time [Time]     Optional end of a time range.
  # @return [Enumerable<Hash>] Enumerable of hashes with `month` and `dl_count`
  #                            keys.
  #
  def download_count_by_month(start_time: nil, end_time: nil)
    start_time ||= Event.all.order(:happened_at).limit(1).pluck(:happened_at).first
    end_time   ||= Time.now.utc
    raise ArgumentError, "End time must be after start time" if start_time > end_time
    end_time    += 1.month
    start_series = "#{start_time.year}-#{start_time.month}-01"
    end_series   = "#{end_time.year}-#{end_time.month}-01"

    sql = "WITH RECURSIVE q AS (
            SELECT c
            FROM collections c
            WHERE id = $1
            UNION ALL
            SELECT ci
            FROM q
            JOIN collections ci ON ci.parent_id = (q.c).id
        )
        SELECT mon.month, coalesce(e.count, 0) AS dl_count
        FROM generate_series('#{start_series}'::timestamp,
                             '#{end_series}'::timestamp, interval '1 month') AS mon(month)
        LEFT JOIN (
            SELECT date_trunc('Month', e.happened_at) as month,
                   COUNT(DISTINCT e.id) AS count
            FROM events e
                LEFT JOIN bitstreams b ON e.bitstream_id = b.id
                LEFT JOIN items i ON b.item_id = i.id
                LEFT JOIN collection_item_memberships cim ON cim.item_id = i.id
                LEFT JOIN q ON cim.collection_id IN (SELECT (q.c).id FROM q)
            WHERE (q.c).id = $1
                AND e.event_type = $2
                AND e.happened_at >= $3
                AND e.happened_at <= $4
            GROUP BY month
        ) e ON mon.month = e.month
        ORDER BY mon.month;"
    values = [self.id, Event::Type::DOWNLOAD, start_time, end_time]
    result = self.class.connection.exec_query(sql, "SQL", values).to_a
    result[0..(result.length - 2)]
  end

  ##
  # @return [Set<User>] All users who are effectively managers of the instance.
  #
  def effective_managers
    set = Set.new
    # Add sysadmins.
    set += UserGroup.sysadmin.all_users
    # Add unit administrators.
    self.units.each do |unit|
      set += unit.all_administrators
    end
    # Add direct managers.
    set += self.managing_users
    # Add managers of parent collections.
    all_parents.each do |parent|
      set += parent.managing_users
    end
    set
  end

  ##
  # @return [MetadataProfile] The metadata profile assigned to the instance, or
  #         the profile assigned to the primary unit, or the institution's
  #         default profile as a last resort.
  #
  def effective_metadata_profile
    #noinspection RubyMismatchedReturnType
    self.metadata_profile || self.primary_unit&.effective_metadata_profile
  end

  ##
  # @return [SubmissionProfile] The submission profile assigned to the
  #         instance, or the owning institution's default profile if no profile
  #         is assigned.
  #
  def effective_submission_profile
    #noinspection RubyMismatchedReturnType
    self.submission_profile || self.institution.default_submission_profile
  end

  ##
  # @return [Set<User>] All users who are effectively able to submit into the
  #                     instance.
  #
  def effective_submitters
    set = Set.new
    set += effective_managers
    # Add direct submitters.
    set += self.submitting_users
    # Add submitters into parent collections.
    all_parents.each do |parent|
      set += parent.submitting_users
    end
    set
  end

  ##
  # Un-buries an instance.
  #
  # @see bury!
  #
  def exhume!
    update!(buried: false) if buried
  end

  ##
  # @param start_time [Time]          Optional beginning of a time range.
  # @param end_time [Time]            Optional end of a time range.
  # @param include_children [Boolean] Whether to include child collections in
  #                                   the count.
  # @return [Integer] Total download count of all bitstreams attached to all
  #                   items in the collection.
  #
  def submitted_item_count(start_time: nil,
                           end_time: nil,
                           include_children: true)
    count = 0
    if include_children
      self.all_children.each do |child_collection|
        count += child_collection.submitted_item_count(start_time:       start_time,
                                                       end_time:         end_time,
                                                       include_children: false)
      end
    end
    items = self.items.where(stage: Item::Stages::SUBMITTED)
    if start_time || end_time
      items = items.joins("LEFT JOIN events ON items.id = events.item_id").
        where("events.event_type": Event::Type::CREATE)
      items = items.where("events.happened_at >= ?", start_time) if start_time
      items = items.where("events.happened_at <= ?", end_time) if end_time
    end
    count + items.count
  end

  ##
  # @param start_time [Time]   Optional beginning of a time range.
  # @param end_time [Time]     Optional end of a time range.
  # @return [Enumerable<Hash>] Enumerable of hashes with `month` and `count`
  #                            keys.
  #
  def submitted_item_count_by_month(start_time: nil, end_time: nil)
    start_time ||= Event.all.order(:happened_at).limit(1).pluck(:happened_at).first
    end_time   ||= Time.now.utc
    raise ArgumentError, "End time must be after start time" if start_time > end_time
    end_time    += 1.month
    start_series = "#{start_time.year}-#{start_time.month}-01"
    end_series   = "#{end_time.year}-#{end_time.month}-01"

    sql = "SELECT mon.month, coalesce(e.count, 0) AS count
    FROM generate_series('#{start_series}'::timestamp,
                         '#{end_series}'::timestamp, interval '1 month') AS mon(month)
    LEFT JOIN (
        SELECT date_trunc('Month', e.happened_at) as month,
               COUNT(DISTINCT e.id) AS count
        FROM events e
            LEFT JOIN items i ON e.item_id = i.id
            LEFT JOIN collection_item_memberships cim ON cim.item_id = i.id
        WHERE cim.collection_id = $1
            AND e.event_type = $2
            AND e.happened_at >= $3
            AND e.happened_at <= $4
        GROUP BY month
    ) e ON mon.month = e.month
    ORDER BY mon.month;"
    values = [self.id, Event::Type::CREATE, start_time, end_time]
    result = self.class.connection.exec_query(sql, "SQL", values).to_a
    result[0..(result.length - 2)]
  end

  def unit_default?
    self.unit_collection_memberships.pluck(:unit_default).find{ |m| m == true }.present?
  end


  private

  ##
  # Ensures that a buried collection does not contain any sub-collections or
  # items.
  #
  def validate_buried
    if buried
      if items.where.not(stage: Item::Stages::BURIED).count > 0
        errors.add(:base, "This collection cannot be deleted, as it contains "\
                          "at least one item.")
        throw(:abort)
      elsif collections.where.not(buried: true).count > 0
        errors.add(:base, "This collection cannot be deleted, as it contains "\
                          "at least one child collection.")
        throw(:abort)
      end
    end
  end

  ##
  # Ensures that the unit cannot be destroyed unless it is empty of
  # subcollections and items.
  #
  def validate_empty
    if self.collections.count > 0
      errors.add(:collections, "must not exist in order for a collection to be deleted")
      throw(:abort)
    elsif self.items.count > 0
      errors.add(:items, "must not exist in order for a collection to be deleted")
      throw(:abort)
    end
  end

  ##
  # Ensures that at least one owning unit of an exhumed collection is not
  # buried.
  #
  def validate_exhumed
    if !buried && buried_changed? && units.where.not(buried: true).count == 0
      errors.add(:base, "This collection cannot be undeleted, as all of its "\
                        "owning units are deleted.")
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
        errors.add(:parent_id, "cannot be set to the same collection")
        throw(:abort)
      elsif all_children.map(&:id).include?(self.parent_id)
        errors.add(:parent_id, "cannot be set to a child collection")
        throw(:abort)
      elsif self.parent.primary_unit != self.primary_unit
        errors.add(:parent_id, "cannot be set to a collection in a different unit")
        throw(:abort)
      end
    end
  end

  ##
  # Ensures that the instance has a primary unit.
  #
  def validate_primary_unit
    if unit_collection_memberships.any? && !primary_unit
      errors.add(:primary_unit, "is not set")
      throw(:abort)
    end
  end

end
