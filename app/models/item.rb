# frozen_string_literal: true

##
# Encapsulates a unit of intellectual content.
#
# # Lifecycle
#
# An item goes through several "life stages":
#
# 1. Creation. This happens during {SubmissionsController submission}. It also
#    happens one time only during the {IdealsImporter migration of data from
#    IDEALS-DSpace into this application}.
#     a. In the former case, the item is marked `submitting = true`,
#        `in_archive = false`, `withdrawn = false`, `discoverable = false`.
#     b. In the latter case, the above properties are carried over from
#        IDEALS-DSpace.
# 2. Submission. In this stage, its properties are edited, metadata is
#    ascribed, and bitstreams are attached/detached.
# 3. Submission complete.
# 4. Ingest into Medusa, where the bitstreams' corresponding files/objects are
#    moved into Medusa.
# 5. Withdrawal. This is an optional stage.
#
# |                     | submitting | in_archive | discoverable | withdrawn |
# |---------------------|------------|------------|--------------|-----------|
# | Creation            |    true    |   false    |    false     |   false   |
# | Submission          |    true    |   false    |    false     |   false   |
# | Submission Complete |    false   |   false    |     true     |   false   |
# | Ingest Into Medusa  |    false   |    true    |     true     |   false   |
# | Withdrawal          |    false   |   true?    |    false     |   false   |
#
# # Indexing
#
# See the documentation of {Indexed} for a detailed explanation of how indexing
# works.
#
# # Attributes
#
# * `created_at`            Managed by ActiveRecord.
# * `discoverable`          If false, the submitter has indicated during
#                           submission that the item should be private, which
#                           means it should not be included in search results,
#                           and its metadata should not be available except to
#                           administrators.
# * `in_archive`            Whether the item's bitstreams have been archived in
#                           the Medusa Collection Registry.
# * `primary_collection_id` Foreign key to {Collection}.
# * `submitter_id`          Foreign key to {User}.
# * `submitting`            Indicates that the item is in the submission
#                           process. This is more-or-less an inversion of
#                           DSpace's `in_archive` property.
# * `updated_at`            Managed by ActiveRecord.
# * `withdrawn`             An administrator has made the item inaccessible,
#                           but not totally deleted it.
#
# # Relationships
#
# * `bitstreams`         References all associated {Bitstream}s.
# * `collections`        References all owning {Collections}.
# * `elements`           References zero-to-many {AscribedElement}s used to
#                        describe an instance.
# * `primary_collection` References the primary {Collection} in which the
#                        instance resides.
#
class Item < ApplicationRecord
  include Breadcrumb
  include Describable
  include Indexed

  ##
  # Contains constants for all "technical" indexed fields. Additional dynamic
  # metadata fields may also be present.
  #
  class IndexFields
    CLASS              = ElasticsearchIndex::StandardFields::CLASS
    COLLECTION_TITLES  = "k_collection_titles"
    COLLECTIONS        = "i_collection_ids"
    CREATED            = ElasticsearchIndex::StandardFields::CREATED
    DISCOVERABLE       = "b_discoverable"
    ID                 = ElasticsearchIndex::StandardFields::ID
    LAST_INDEXED       = ElasticsearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED      = ElasticsearchIndex::StandardFields::LAST_MODIFIED
    PRIMARY_COLLECTION = "i_primary_collection_id"
    PRIMARY_UNIT       = "i_primary_unit_id"
    SUBMITTER          = "i_submitter_id"
    SUBMITTING         = "b_submitting"
    UNIT_TITLES        = "k_unit_titles"
    UNITS              = "i_unit_ids"
    WITHDRAWN          = "b_withdrawn"
  end

  has_many :bitstreams
  has_and_belongs_to_many :collections
  has_many :elements, class_name: "AscribedElement"
  belongs_to :primary_collection, class_name: "Collection",
             foreign_key: "primary_collection_id", optional: true
  belongs_to :submitter, class_name: "User", inverse_of: "submitted_items",
             optional: true

  breadcrumbs parent: :primary_collection, label: :title

  ##
  # @param submitter [User]
  # @param primary_collection_id [Integer]
  # @return [Item] New persisted instance.
  #
  def self.new_for_submission(submitter:, primary_collection_id:)
    item = Item.create!(submitter: submitter,
                        primary_collection_id: primary_collection_id,
                        submitting: true,
                        in_archive: false,
                        discoverable: false)
    # For every element with placeholder text in the item's effective
    # submission profile, ascribe a metadata element with a value of that text.
    item.effective_submission_profile.elements.where("placeholder_text IS NOT NULL").each do |sp_element|
      item.elements.build(registered_element: sp_element.registered_element,
                          string: sp_element.placeholder_text).save!
    end
    item
  end

  ##
  # @return [Enumerable<User>] All managers of all owning collections,
  #                            including the primary one.
  #
  def all_collection_managers
    bucket = Set.new
    all_collections.each do |col|
      bucket += col.managing_users
    end
    bucket
  end

  ##
  # @return [Enumerable<User>] All submitters to all owning collections,
  #                            including the primary one.
  #
  def all_collection_submitters
    bucket = Set.new
    all_collections.each do |col|
      bucket += col.submitting_users
    end
    bucket
  end

  ##
  # @return [Enumerable<Collection>] All owning collections, including the
  #                                  primary one.
  #
  def all_collections
    bucket = Set.new
    bucket << self.primary_collection if self.primary_collection_id
    bucket += collections
    bucket
  end

  ##
  # @return [Enumerable<Unit>] All owning units.
  #
  def all_units
    bucket = Set.new
    all_collections.each do |collection|
      bucket += collection.all_units
    end
    bucket
  end

  ##
  # @return [Enumerable<User>]
  #
  def all_unit_administrators
    bucket = Set.new
    all_units.each do |unit|
      bucket += unit.all_administrators
    end
    bucket
  end

  ##
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json
    doc = {}
    doc[IndexFields::CLASS]              = self.class.to_s
    collections = self.all_collections
    doc[IndexFields::COLLECTION_TITLES]  = collections.map(&:title)
    doc[IndexFields::COLLECTIONS]        = collections.map(&:id)
    doc[IndexFields::CREATED]            = self.created_at.utc.iso8601
    doc[IndexFields::DISCOVERABLE]       = self.discoverable
    doc[IndexFields::LAST_INDEXED]       = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED]      = self.updated_at.utc.iso8601
    doc[IndexFields::PRIMARY_COLLECTION] = self.primary_collection_id
    doc[IndexFields::PRIMARY_UNIT]       = self.primary_unit&.id
    doc[IndexFields::SUBMITTER]          = self.submitter_id
    doc[IndexFields::SUBMITTING]         = self.submitting
    units = self.all_units
    doc[IndexFields::UNIT_TITLES]        = units.map(&:title)
    doc[IndexFields::UNITS]              = units.map(&:id)
    doc[IndexFields::WITHDRAWN]          = self.withdrawn

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
  # @return [MetadataProfile] The primary collection's metadata profile, or the
  #                           {MetadataProfile#default default profile} if not
  #                           set.
  #
  def effective_metadata_profile
    self.primary_collection&.effective_metadata_profile || MetadataProfile.default
  end

  ##
  # @return [SubmissionProfile] The primary collection's submission profile, o
  #                             the {SubmissionProfile#default default profile}
  #                             if not set.
  #
  def effective_submission_profile
    self.primary_collection&.effective_submission_profile || SubmissionProfile.default
  end

  def label
    title
  end

  ##
  # @return [MetadataProfile] Effective metadata profile of the primary
  #                           {Collection}.
  #
  def metadata_profile
    primary_collection.effective_metadata_profile
  end

  ##
  # @return [Unit]
  #
  def primary_unit
    #noinspection RubyYardReturnMatch
    self.primary_collection&.primary_unit
  end

end
