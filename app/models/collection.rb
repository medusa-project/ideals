# frozen_string_literal: true

##
# A collection is a container for {Item}s. It resides within a {Unit}. It
# supports a one-to-many parent-children relationship with itself.
#
# # Indexing
#
# See the documentation of {Indexed} for a detailed explanation of how indexing
# works.
#
# # Attributes
#
# * `created_at`            Managed by ActiveRecord.
# * `introduction`          Introduction string. May contain HTML.
# * `metadata_profile_id`   Foreign key to {MetadataProfile}. Instances without
#                           this set should use the {MetadataProfile#default
#                           default profile}. In most cases,
#                           {effective_metadata_profile} should be used instead
#                           of accessing this directly.
# * `provenance`            Provenance string.
# * `rights`                Rights string.
# * `short_description`     Short description string.
# * `submission_profile_id` Foreign key to {SubmissionProfile}. Instances
#                           without this set should use the
#                           {SubmissionProfile#default default profile}. In
#                           most cases, {effective_submission_profile} should
#                           be used instead of accessing this directly.
# * `submissions_reviewed`  If true, items submitted to the collection are
#                           subject to administrator review. Otherwise, they
#                           are immediately approved.
# * `updated_at`            Managed by ActiveRecord.
#
# # Relationships
#
# * `collections`         References zero-to-many sub-{Collection}s.
# * `elements`            References zero-to-many {AscribedElement}s used to
#                         describe an instance.
# * `items`               References all {Items} contained within the instance.
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
# * `submissions`         References all {Submissions} into the instance.
# * `submitters`          References all {Submitter}s who are allowed to submit
#                         {Item}s to the instance.
# * `submitting_users`    More useful alternative to {submitters} that returns
#                         {User}s instead.
# * `units`               References all units to which the instance directly
#                         belongs.
#
class Collection < ApplicationRecord
  include Breadcrumb
  include Indexed

  class IndexFields
    CLASS             = ElasticsearchIndex::StandardFields::CLASS
    CREATED           = ElasticsearchIndex::StandardFields::CREATED
    DESCRIPTION       = "t_description"
    ID                = ElasticsearchIndex::StandardFields::ID
    INSTITUTION_KEY   = ElasticsearchIndex::StandardFields::INSTITUTION_KEY
    INTRODUCTION      = "t_introduction"
    LAST_INDEXED      = ElasticsearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED     = ElasticsearchIndex::StandardFields::LAST_MODIFIED
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

  after_save :assign_handle, if: -> { handle.nil? && !IdealsImporter.instance.running? }

  breadcrumbs parent: :primary_unit, label: :title

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
    values = [[ nil, self.id ]]

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
    doc[IndexFields::CLASS]             = self.class.to_s
    doc[IndexFields::CREATED]           = self.created_at.utc.iso8601
    doc[IndexFields::DESCRIPTION]       = self.description
    doc[IndexFields::INSTITUTION_KEY]   = units.first&.institution&.key
    doc[IndexFields::INTRODUCTION]      = self.introduction
    doc[IndexFields::LAST_INDEXED]      = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED]     = self.updated_at.utc.iso8601
    doc[IndexFields::MANAGERS]          = self.effective_managers.map(&:id)
    doc[IndexFields::PARENT]            = self.parent_id
    doc[IndexFields::PRIMARY_UNIT]      = self.primary_unit&.id
    doc[IndexFields::PROVENANCE]        = self.provenance
    doc[IndexFields::RIGHTS]            = self.rights
    doc[IndexFields::SHORT_DESCRIPTION] = self.short_description
    doc[IndexFields::SUBMITTERS]        = self.effective_submitters.map(&:id)
    doc[IndexFields::TITLE]             = self.title
    doc[IndexFields::UNIT_DEFAULT]      = self.unit_default?
    doc[IndexFields::UNIT_TITLES]       = units.map(&:title)
    doc[IndexFields::UNITS]             = self.unit_ids
    doc
  end

  def breadcrumb_label
    title
  end

  ##
  # @param start_time [Time]          Optional beginning of a time range.
  # @param end_time [Time]            Optional end of a time range.
  # @param include_children [Boolean] Whether to include child collections in
  #                                   the count.
  # @return [Integer] Total download count of all bitstreams attached to all
  #                   items in the collection.
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
    items = self.items.
      joins("LEFT JOIN bitstreams ON bitstreams.item_id = items.id").
      joins("LEFT JOIN events ON bitstreams.id = events.bitstream_id").
      where("events.event_type": Event::Type::DOWNLOAD)
    items = items.where("events.happened_at >= ?", start_time) if start_time
    items = items.where("events.happened_at <= ?", end_time) if end_time
    count + items.count
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

    sql = "SELECT mon.month, coalesce(e.count, 0) AS dl_count
        FROM generate_series('#{start_time.strftime("%Y-%m-%d")}'::timestamp,
                             '#{end_time.strftime("%Y-%m-%d")}'::timestamp, interval '1 month') AS mon(month)
            LEFT JOIN (
                SELECT date_trunc('Month', e.happened_at) as month,
                       COUNT(e.id) AS count
                FROM events e
                    LEFT JOIN bitstreams b on e.bitstream_id = b.id
                    LEFT JOIN items i ON b.item_id = i.id
                    LEFT JOIN collection_item_memberships cim ON cim.item_id = i.id
                WHERE cim.collection_id = $1
                    AND e.event_type = $2
                    AND e.happened_at >= $3
                    AND e.happened_at <= $4
                GROUP BY month) e ON mon.month = e.month
        ORDER BY mon.month;"
    values = [[nil, self.id], [nil, Event::Type::DOWNLOAD],
              [nil, start_time], [nil, end_time]]
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
  #                            their corresponding download counts. Items in
  #                            child collections are not included.
  #
  def item_download_counts(offset: 0, limit: 0,
                           start_time: nil, end_time: nil)
    sql = StringIO.new
    sql << "SELECT *
        FROM (
            SELECT DISTINCT ON (i.id) i.id AS id, ae.string AS title, COUNT(e.id) AS dl_count
            FROM items i
                LEFT JOIN ascribed_elements ae ON ae.item_id = i.id
                LEFT JOIN registered_elements re ON re.id = ae.registered_element_id
                LEFT JOIN collection_item_memberships m ON m.item_id = i.id
                LEFT JOIN bitstreams b ON b.item_id = i.id
                LEFT JOIN events e ON e.bitstream_id = b.id
            WHERE re.name = $1
                AND m.collection_id = $2
                AND e.event_type = $3 "
    sql <<      "AND e.happened_at >= $4 " if start_time
    sql <<      "AND e.happened_at <= #{start_time ? "$5" : "$4"} " if end_time
    sql <<  "GROUP BY i.id, ae.string"
    sql << ") items_with_dl_count "
    sql << "ORDER BY items_with_dl_count.dl_count DESC "
    sql << "OFFSET #{offset} " if offset > 0
    sql << "LIMIT #{limit} " if limit > 0

    values = [
      [nil, ::Configuration.instance.elements[:title]],
      [nil, self.id],
      [nil, Event::Type::DOWNLOAD]
    ]
    values << [nil, start_time] if start_time
    values << [nil, end_time] if end_time
    self.class.connection.exec_query(sql.string, 'SQL', values)
  end

  ##
  # @return [Set<User>] All users who are effectively managers of the instance.
  #
  def effective_managers
    set = Set.new
    # Add sysadmins.
    set += UserGroup.sysadmin.all_users
    # Add administrators of the primary unit.
    set += primary_unit.all_administrators if primary_unit
    # Add administrators of other units.
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
  #         the default profile if no profile is assigned.
  #
  def effective_metadata_profile
    #noinspection RubyYardReturnMatch
    self.metadata_profile || MetadataProfile.default
  end

  ##
  # @return [SubmissionProfile] The submission profile assigned to the
  #         instance, or the default profile if no profile is assigned.
  #
  def effective_submission_profile
    #noinspection RubyYardReturnMatch
    self.submission_profile || SubmissionProfile.default
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
  # @return [Institution]
  #
  def institution
    primary_unit.institution
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
    items = self.items.
        joins("LEFT JOIN events ON items.id = events.item_id").
        where("events.event_type": Event::Type::CREATE)
    items = items.where("events.happened_at >= ?", start_time) if start_time
    items = items.where("events.happened_at <= ?", end_time) if end_time
    count + items.count
  end

  ##
  # @param start_time [Time]   Optional beginning of a time range.
  # @param end_time [Time]     Optional end of a time range.
  # @return [Enumerable<Hash>] Enumerable of hashes with `month` and `count`
  #                            keys.
  #
  def submitted_item_count_by_month(start_time: nil, end_time: nil)
    start_time = Event.all.order(:happened_at).limit(1).pluck(:happened_at).first unless start_time
    end_time   = Time.now unless end_time

    sql = "SELECT mon.month, coalesce(e.count, 0) AS count
        FROM generate_series('#{start_time.strftime("%Y-%m-%d")}'::timestamp,
                             '#{end_time.strftime("%Y-%m-%d")}'::timestamp, interval '1 month') AS mon(month)
            LEFT JOIN (
                SELECT date_trunc('Month', e.happened_at) as month,
                       COUNT(e.id) AS count
                FROM events e
                    LEFT JOIN items i ON e.item_id = i.id
                    LEFT JOIN collection_item_memberships cim ON cim.item_id = i.id
                WHERE cim.collection_id = $1
                    AND e.event_type = $2
                    AND e.happened_at >= $3
                    AND e.happened_at <= $4
                GROUP BY month) e ON mon.month = e.month
        ORDER BY mon.month;"
    values = [[nil, self.id], [nil, Event::Type::CREATE],
              [nil, start_time], [nil, end_time]]
    self.class.connection.exec_query(sql, "SQL", values)
  end

  def unit_default?
    self.unit_collection_memberships.pluck(:unit_default).find{ |m| m == true }.present?
  end


  private

  ##
  # @return [void]
  #
  def assign_handle
    if self.handle.nil? && !IdealsImporter.instance.running?
      self.handle = Handle.create!(collection: self)
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
      elsif all_children.map(&:id).include?(self.parent_id)
        errors.add(:parent_id, "cannot be set to a child collection")
      elsif self.parent.primary_unit != self.primary_unit
        errors.add(:parent_id, "cannot be set to a collection in a different unit")
      end
    end
  end

  ##
  # Ensures that the instance has a primary unit.
  #
  def validate_primary_unit
    errors.add(:primary_unit, "is not set") if unit_collection_memberships.any? && !primary_unit
  end

end
