# frozen_string_literal: true

##
# High-level container for {Collection}s, analogous to a "community" in DSpace.
#
# # Indexing
#
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
# * `buried`              Indicates a "near-deletion" which leaves behind only
#                         a row in the units table that facilitates display of
#                         a tombstone record. The burial is not reversible.
# * `created_at`          Managed by ActiveRecord.
# * `institution_id`      Foreign key to {Institution}.
# * `introduction`        Introduction string. May contain HTML.
# * `metadata_profile_id` Foreign key to {MetadataProfile}. Instances without
#                         this set will use the
#                         {Institution#default_metadata_profile default
#                         metadata profile of the institution}. Child
#                         collections may override it with their own
#                         {metadata_profile} property. In most cases,
#                         {effective_metadata_profile} should be used instead
#                         of accessing this directly.
# * `parent_id`           Foreign key to a parent {Unit}.
# * `rights`              Rights string.
# * `short_description`   Short description string.
# * `title`               Unit title.
# * `updated_at`          Managed by ActiveRecord.
#
class Unit < ApplicationRecord

  include Auditable
  include Breadcrumb
  include Handled
  include Indexed

  class IndexFields
    ADMINISTRATORS        = "i_administrator_id"
    BURIED                = "b_buried"
    CLASS                 = OpenSearchIndex::StandardFields::CLASS
    CREATED               = OpenSearchIndex::StandardFields::CREATED
    HANDLE                = "k_handle"
    ID                    = OpenSearchIndex::StandardFields::ID
    INSTITUTION_KEY       = OpenSearchIndex::StandardFields::INSTITUTION_KEY
    INSTITUTION_NAME      = OpenSearchIndex::StandardFields::INSTITUTION_NAME
    INTRODUCTION          = "t_introduction"
    LAST_INDEXED          = OpenSearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED         = OpenSearchIndex::StandardFields::LAST_MODIFIED
    PARENT                = "i_parent_id"
    PRIMARY_ADMINISTRATOR = "i_primary_administrator_id"
    RIGHTS                = "t_rights"
    SHORT_DESCRIPTION     = "t_short_description"
    TITLE                 = "t_title"
  end

  belongs_to :institution
  belongs_to :metadata_profile, inverse_of: :units, optional: true
  belongs_to :parent, class_name: "Unit", foreign_key: "parent_id", optional: true

  has_many :administrators, class_name: "UnitAdministrator"
  has_many :administering_users, through: :administrators,
           class_name: "User", source: :user
  has_many :administrator_groups, class_name: "UnitAdministratorGroup"
  has_many :administering_groups, through: :administrator_groups,
           class_name: "UserGroup", source: :user_group
  has_many :events
  has_many :unit_collection_memberships
  has_many :collections, through: :unit_collection_memberships
  has_many :items, through: :collections
  has_many :units, foreign_key: "parent_id", dependent: :restrict_with_exception
  has_one :handle
  has_one :primary_administrator_relationship, -> { where(primary: true) },
          class_name: "UnitAdministrator"
  has_one :primary_administrator, through: :primary_administrator_relationship,
          source: :user

  validates :title, presence: true
  validate :validate_bury, if: -> { buried }
  validate :validate_parent, :validate_primary_administrator

  before_destroy :validate_destroy

  ##
  # @return [Enumerable<Integer>] IDs of all units that are children of the
  #                               instance, at any level in the tree.
  # @see walk_tree
  #
  def all_child_ids
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
    results.
      select{ |row| row['id'] != self.id }.
      map{ |row| row['id'] }
  end

  ##
  # @return [Enumerable<Unit>] All units that are children of the instance, at
  #                            any level in the tree.
  # @see walk_tree
  #
  def all_children
    Unit.where(id: all_child_ids)
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
    doc[IndexFields::HANDLE]                = self.handle&.handle
    doc[IndexFields::INSTITUTION_KEY]       = self.institution&.key
    doc[IndexFields::INSTITUTION_NAME]      = self.institution&.name
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

  def breadcrumb_label
    self.title
  end

  def breadcrumb_parent
    self.parent || Unit
  end

  ##
  # Renders an instance almost totally deleted, leaving behind a tombstone
  # record.
  #
  # @raises [RuntimeError] if the instance contains any dependent collections.
  # @see exhume!
  #
  def bury!
    update!(buried: true) unless buried
  end

  ##
  # @return [Boolean] Whether the instance if a child of another {Unit}.
  #
  def child?
    self.parent_id.present?
  end

  ##
  # Compiles monthly download counts for a given time span by querying the
  # `events` table.
  #
  # Note that {MonthlyUnitItemDownloadCount#for_unit} uses a different
  # technique--querying the monthly unit item download count reporting table--
  # that is much faster.
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
    ids          = self.all_child_ids + [self.id]

    sql = "SELECT mon.month, coalesce(e.count, 0) AS dl_count
        FROM generate_series('#{start_series}'::timestamp,
                             '#{end_series}'::timestamp, interval '1 month') AS mon(month)
        LEFT JOIN (
            SELECT date_trunc('Month', e.happened_at) as month,
                   COUNT(DISTINCT e.id) AS count
            FROM events e
                LEFT JOIN bitstreams b on e.bitstream_id = b.id
                LEFT JOIN items i ON b.item_id = i.id
                LEFT JOIN collection_item_memberships cim ON cim.item_id = i.id
                LEFT JOIN unit_collection_memberships ucm ON ucm.collection_id = cim.collection_id
            WHERE ucm.unit_id IN (#{ids.join(",")})
                AND e.event_type = $1
                AND e.happened_at >= $2
                AND e.happened_at <= $3
            GROUP BY month
        ) e ON mon.month = e.month
        ORDER BY mon.month;"
    values = [Event::Type::DOWNLOAD, start_time, end_time]
    result = self.class.connection.exec_query(sql, "SQL", values).to_a
    result[0..(result.length - 2)]
  end

  ##
  # @return [Enumerable<UserGroup>]
  #
  def effective_administering_groups
    unless @effective_administering_groups
      @effective_administering_groups = Set.new
      # Add the sysadmin group.
      @effective_administering_groups << UserGroup.sysadmin
      # Add direct administrators of the instance.
      @effective_administering_groups += self.administering_groups
      # Add administrators of parents.
      all_parents.each do |parent|
        @effective_administering_groups += parent.administering_groups
      end
      # Add administrators of the institution.
      @effective_administering_groups += self.institution.administering_groups
    end
    @effective_administering_groups
  end

  ##
  # @return [Enumerable<User>]
  #
  def effective_administering_users
    unless @effective_administering_users
      @effective_administering_users = Set.new
      # Add direct administrators of the instance.
      @effective_administering_users += self.administering_users
      # Add administrators of parents.
      all_parents.each do |parent|
        @effective_administering_users += parent.administering_users
      end
      # Add administrators of the institution.
      @effective_administering_users += self.institution.administering_users
    end
    @effective_administering_users
  end

  ##
  # @return [MetadataProfile] The metadata profile assigned to the instance, or
  #         the owning institution's default metadata profile if no profile is
  #         assigned to the instance.
  #
  def effective_metadata_profile
    #noinspection RubyMismatchedReturnType
    self.metadata_profile || self.institution.default_metadata_profile
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
  # Moves the instance and its whole subtree of child units, {Collection}s, and
  # {Item}s to another institution. {AscribedElement}s are also moved and
  # reconfigured to associate with {RegisteredElement}s in the destination
  # institution, which are created if necessary to match the ones in the source
  # institution.
  #
  # The unit is placed at the root level within the institution and is
  # disassociated from any {User}s and {MetadataProfile}s. Likewise, its child
  # collections are disassociated from any {User}s, {MetadataProfile}s, and
  # {SubmissionProfile}s, and its items are disassociated from any
  # {BitstreamAuthorization}s.
  #
  # {Unit}, {Collection}, and {Item} IDs are not changed. Consideration must be
  # made to redirect URLs to the new institution's host, which is done in the
  # controllers.
  #
  # Lastly, {Bitstream}s' permanent keys are changed to use the new institution
  # prefix.
  #
  # N.B.: this method could cause some real headaches if it isn't working 100%
  # correctly, so its implementation should be scrutinized carefully before
  # use. It is expected to be used very rarely so bugs may rear up at any
  # point (following design changes elsewhere) even without any test failures.
  #
  # @param institution [Institution]
  # @param user [User] The user performing the action, who should be a
  #                    sysadmin, although this is enforced in a policy method
  #                    rather than here.
  #
  def move_to(institution:, user:)
    if !institution
      raise ArgumentError, "Institution not provided"
    elsif !user
      raise ArgumentError, "User not provided"
    elsif institution == self.institution
      raise ArgumentError, "Cannot move to the same institution"
    elsif Unit.find_by(institution: institution, title: self.title)
      raise "A unit with the same name already exists in the destination institution."
    end
    prev_institution = self.institution
    from_units       = [self] + all_children
    dest_reg_e_names = institution.registered_elements.pluck(:name)
    # Compute a count of entities that will need to be traversed in order to
    # display progress.
    entity_count = 0
    from_units.each do |unit|
      entity_count += 1
      unit.collections.each do |collection|
        entity_count += 1
        entity_count += collection.items.count
      end
    end
    self.update!(parent_id: nil)
    progress   = Progress.new(entity_count)
    entity_idx = 0
    Unit.transaction do
      Unit.uncached do
        from_units.each do |unit|
          progress.report(entity_idx, "Moving #{unit.title} to #{institution.name}")
          unit.administrators.destroy_all
          unit.administrator_groups.destroy_all
          unit.update!(institution_id:   institution.id,
                       metadata_profile: nil)
          unit.collections.each do |collection|
            progress.report(entity_idx, "Moving #{collection.title} to #{institution.name}")
            collection.administrators.destroy_all
            collection.submitters.destroy_all
            collection.update!(institution_id:     institution.id,
                               metadata_profile:   nil,
                               submission_profile: nil)
            collection.items.find_each do |item|
              progress.report(entity_idx, "Moving #{item.title} to #{institution.name}")
              UpdateItemCommand.new(item:        item,
                                    user:        user,
                                    description: "Moved to #{institution.name}").execute do
                item.update!(institution_id: institution.id)
                item.bitstream_authorizations.destroy_all
                # Migrate item elements
                item.elements.each do |asc_e|
                  name = asc_e.registered_element.name
                  unless dest_reg_e_names.include?(name)
                    clone             = asc_e.registered_element.dup
                    clone.institution = institution
                    clone.scope_note  = "Added during a migration of the unit "\
                         "\"#{self.title}\" from the institution "\
                         "#{self.institution.name} on "\
                         "#{Time.now.strftime("%Y-%m-%d")}."
                    clone.save!
                    dest_reg_e_names << name
                  end
                  asc_e.update!(registered_element:
                                  institution.registered_elements.find_by_name(name))
                end
                # Migrate item bitstreams
                item.bitstreams.each do |bitstream|
                  if bitstream.permanent_key.present?
                    if bitstream.medusa_uuid.present?
                      bitstream.delete_from_medusa(institution: prev_institution)
                    end
                    # Generate a new permanent key (with changed institution prefix)
                    new_key = Bitstream.permanent_key(institution_key: institution.key,
                                                      item_id:         item.id,
                                                      filename:        bitstream.filename)
                    bitstream.update!(permanent_key: new_key)
                    bitstream.ingest_into_medusa
                  elsif bitstream.staging_key.present?
                    # Generate a new staging key (with changed institution prefix)
                    new_key = Bitstream.staging_key(institution_key: institution.key,
                                                    item_id:         item.id,
                                                    filename:        bitstream.filename)
                    bitstream.update!(staging_key: new_key)
                  end
                end
              end
              entity_idx += 1
            end
            entity_idx += 1
          end
          entity_idx += 1
        end
      end
    end
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
    start_time ||= Event.all.order(:happened_at).limit(1).pluck(:happened_at).first
    end_time   ||= Time.now.utc
    raise ArgumentError, "End time must be after start time" if start_time > end_time
    end_time    += 1.month
    start_series = "#{start_time.year}-#{start_time.month}-01"
    end_series   = "#{end_time.year}-#{end_time.month}-01"

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
    FROM generate_series('#{start_series}'::timestamp,
                         '#{end_series}'::timestamp, interval '1 month') AS mon(month)
    LEFT JOIN (
        SELECT date_trunc('Month', e.happened_at) as month,
               COUNT(DISTINCT e.id) AS count
        FROM events e
            LEFT JOIN items i ON e.item_id = i.id
            LEFT JOIN collection_item_memberships cim ON cim.item_id = i.id
            LEFT JOIN unit_collection_memberships ucm ON ucm.collection_id = cim.collection_id
            LEFT JOIN q ON ucm.unit_id IN (SELECT (q.u).id FROM q)
        WHERE (q.u).id = $1
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


  private

  ##
  # Ensures that a buried unit does not contain any collections.
  #
  def validate_bury
    if buried
      if units.where.not(buried: true).exists?
        errors.add(:base, "This unit cannot be deleted, as it contains at "\
                          "least one child unit.")
        throw(:abort)
      elsif collections.where.not(buried: true).exists?
        errors.add(:base, "This unit cannot be deleted, as it contains at "\
                          "least one collection.")
        throw(:abort)
      end
    end
  end

  ##
  # Ensures that the unit cannot be destroyed unless it is empty.
  #
  def validate_destroy
    if self.units.exists?
      errors.add(:units, "must not exist in order for a unit to be deleted")
      throw(:abort)
    elsif self.collections.exists?
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
        throw(:abort)
      elsif all_children.map(&:id).include?(self.parent_id)
        errors.add(:parent_id, "cannot be set to a child unit")
        throw(:abort)
      end
    end
  end

  ##
  # Ensures that only top-level units can have a primary administrator
  # assigned.
  #
  def validate_primary_administrator
    if self.parent_id.present? && self.primary_administrator.present?
      errors.add(:primary_administrator, "cannot be set on child units")
      throw(:abort)
    end
  end

end
