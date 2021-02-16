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
# * `metadata_profile_id`   Foreign key to {MetadataProfile}. Instances without
#                           this set should use the {MetadataProfile#default
#                           default profile}. In most cases,
#                           {effective_metadata_profile} should be used instead
#                           of accessing this directly.
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
  include Describable
  include Indexed

  class IndexFields
    CLASS           = ElasticsearchIndex::StandardFields::CLASS
    CREATED         = ElasticsearchIndex::StandardFields::CREATED
    ID              = ElasticsearchIndex::StandardFields::ID
    INSTITUTION_KEY = ElasticsearchIndex::StandardFields::INSTITUTION_KEY
    LAST_INDEXED    = ElasticsearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED   = ElasticsearchIndex::StandardFields::LAST_MODIFIED
    MANAGERS        = "i_manager_id"
    PARENT          = "i_parent_id"
    PRIMARY_UNIT    = "i_primary_unit_id"
    SUBMITTERS      = "i_submitter_id"
    UNIT_DEFAULT    = "b_unit_default"
    UNIT_TITLES     = "s_unit_titles"
    UNITS           = "i_units"
  end

  has_many :collections, foreign_key: "parent_id",
           dependent: :restrict_with_exception
  has_many :elements, class_name: "AscribedElement"
  has_one :handle
  has_many :collection_item_memberships
  has_many :items, through: :collection_item_memberships
  belongs_to :metadata_profile, inverse_of: :collections, optional: true
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
  has_many :submitters
  has_many :submitting_users, through: :submitters,
           class_name: "User", source: :user
  has_many :unit_collection_memberships
  has_many :units, through: :unit_collection_memberships

  validate :validate_parent

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
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json
    doc = {}
    units                             = self.units
    doc[IndexFields::CLASS]           = self.class.to_s
    doc[IndexFields::CREATED]         = self.created_at.utc.iso8601
    doc[IndexFields::INSTITUTION_KEY] = units.first&.institution&.key
    doc[IndexFields::LAST_INDEXED]    = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED]   = self.updated_at.utc.iso8601
    doc[IndexFields::MANAGERS]        = self.effective_managers.map(&:id)
    doc[IndexFields::PARENT]          = self.parent_id
    doc[IndexFields::PRIMARY_UNIT]    = self.primary_unit&.id
    doc[IndexFields::SUBMITTERS]      = self.effective_submitters.map(&:id)
    doc[IndexFields::UNIT_DEFAULT]    = self.unit_default?
    doc[IndexFields::UNIT_TITLES]     = units.map(&:title)
    doc[IndexFields::UNITS]           = self.unit_ids

    # Index ascribed metadata elements into dynamic fields.
    self.elements.each do |element|
      field = element.registered_element.indexed_name
      unless doc[field]&.respond_to?(:each)
        doc[field] = []
      end
      doc[field] << element.string[0..ElasticsearchClient::MAX_KEYWORD_FIELD_LENGTH]
    end

    doc
  end

  ##
  # @param include_children [Boolean] Whether to include child collections in
  #                                   the count.
  # @return [Integer] Total download count of all bitstreams attached to all
  #                   items in the collection.
  #
  def download_count(include_children: true)
    count = 0
    if include_children
      self.all_children.each do |child|
        count += child.download_count(include_children: false)
      end
    end
    count + self.items.joins(:bitstreams).sum("bitstreams.download_count")
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
  # @return [Unit] The primary unit, if set; otherwise, any other unit in the
  #                {units} association.
  # @deprecated TODO: ensure that all items have a primary collection and get rid of this
  #
  def effective_primary_unit
    #noinspection RubyYardReturnMatch
    self.primary_unit || self.units.first
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

  def label
    title
  end

  ##
  # @param include_children [Boolean] Whether to include child collections in
  #                                   the count.
  # @return [Integer] Total download count of all bitstreams attached to all
  #                   items in the collection.
  #
  def submitted_item_count(include_children: true)
    count = 0
    if include_children
      self.all_children.each do |child_collection|
        count += child_collection.submitted_item_count(include_children: false)
      end
    end
    count + self.items.where(stage: Item::Stages::SUBMITTED).count
  end

  def unit_default?
    self.unit_collection_memberships.pluck(:unit_default).find{ |m| m == true }
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

end
