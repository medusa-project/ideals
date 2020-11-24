# frozen_string_literal: true

##
# Encapsulates a unit of intellectual content.
#
# # Lifecycle
#
# An item proceeds through several "life stages", indicated by the {stage}
# attribute and documented in the {Stages} class.
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
# * `primary_collection_id` Foreign key to {Collection}.
# * `stage`                 Lifecycle stage, whose value is one of the {Stages}
#                           constant values.
# * `submitter_id`          Foreign key to {User}.
# * `updated_at`            Managed by ActiveRecord.
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
    GROUP_BY_UNIT_AND_COLLECTION_SORT_KEY = "k_unit_collection_sort_key"
    ID                 = ElasticsearchIndex::StandardFields::ID
    LAST_INDEXED       = ElasticsearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED      = ElasticsearchIndex::StandardFields::LAST_MODIFIED
    PRIMARY_COLLECTION = "i_primary_collection_id"
    PRIMARY_UNIT       = "i_primary_unit_id"
    STAGE              = "i_stage"
    SUBMITTER          = "i_submitter_id"
    UNIT_TITLES        = "k_unit_titles"
    UNITS              = "i_unit_ids"
  end

  ##
  # Class containing valid values for the {Item#stage} attribute.
  #
  class Stages
    ##
    # A newly created item. An item may not be in this stage for long (or maybe
    # even at all) as most items are created at the beginning of a submission,
    # which would place them in the {SUBMITTING} stage. This stage allows for
    # items to be created outside of a submission, whether or not that ends up
    # being a use case.
    NEW        = 0

    ##
    # An item that is going through the submission workflow. In this stage, its
    # properties are edited, metadata is ascribed, and {Bitstream}s are
    # attached/detached. (The bitstreams are staged in the application S3
    # bucket.)
    SUBMITTING = 100

    ##
    # An item that has gone through the submission workflow but has not yet
    # been reviewed. This stage is only available when
    # {Collection#submissions_reviewed submissions to the item's primary
    # collection are reviewed}.
    SUBMITTED  = 200

    ##
    # An item that has completed the submission workflow and been approved by
    # an administrator. Once approved, its bitstreams are ingested into Medusa
    # and their staging counterparts deleted.
    APPROVED   = 300

    ##
    # An item that has completed the submission workflow and been rejected by
    # an administrator.
    REJECTED   = 350

    ##
    # An item that has been withdrawn, a.k.a. made no longer discoverable, by
    # an administrator.
    WITHDRAWN  = 400

    def self.all
      Item::Stages.constants.map{ |c| Item::Stages::const_get(c) }.sort
    end
  end

  has_many :bitstreams
  has_and_belongs_to_many :collections
  has_many :elements, class_name: "AscribedElement"
  has_one :handle
  belongs_to :primary_collection, class_name: "Collection",
             foreign_key: "primary_collection_id", optional: true
  belongs_to :submitter, class_name: "User", inverse_of: "submitted_items",
             optional: true

  breadcrumbs parent: :primary_collection, label: :title

  before_save :email_after_submission
  before_destroy :restrict_in_archive_deletion

  validates :stage, inclusion: { in: Stages.all }
  validate :submission_includes_bitstreams,
           :submission_includes_required_elements

  ##
  # @param submitter [User]
  # @param primary_collection_id [Integer]
  # @return [Item] New persisted instance.
  #
  def self.new_for_submission(submitter:, primary_collection_id:)
    item = Item.create!(submitter: submitter,
                        primary_collection_id: primary_collection_id,
                        stage: Item::Stages::SUBMITTING,
                        discoverable: false)
    # For every element with placeholder text in the item's effective
    # submission profile, ascribe a metadata element with a value of that text.
    item.effective_submission_profile.elements.
        where("LENGTH(placeholder_text) > ?", 0).each do |sp_element|
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
  # @return [Boolean] Whether {stage} is set to {Stages#APPROVED}.
  #
  def approved?
    self.stage == Stages::APPROVED
  end

  ##
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json
    doc = {}
    doc[IndexFields::CLASS]              = self.class.to_s
    collections                          = self.all_collections
    doc[IndexFields::COLLECTION_TITLES]  = collections.map(&:title)
    doc[IndexFields::COLLECTIONS]        = collections.map(&:id)
    doc[IndexFields::CREATED]            = self.created_at.utc.iso8601
    doc[IndexFields::DISCOVERABLE]       = self.discoverable
    doc[IndexFields::GROUP_BY_UNIT_AND_COLLECTION_SORT_KEY] =
        self.unit_and_collection_sort_key
    doc[IndexFields::LAST_INDEXED]       = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED]      = self.updated_at.utc.iso8601
    doc[IndexFields::PRIMARY_COLLECTION] = self.primary_collection_id
    doc[IndexFields::PRIMARY_UNIT]       = self.primary_unit&.id
    doc[IndexFields::STAGE]              = self.stage
    doc[IndexFields::SUBMITTER]          = self.submitter_id
    units                                = self.all_units
    doc[IndexFields::UNIT_TITLES]        = units.map(&:title)
    doc[IndexFields::UNITS]              = units.map(&:id)

    # Index ascribed metadata elements into dynamic fields.
    self.elements.each do |element|
      field = element.registered_element.indexed_name
      doc[field] = [] unless doc[field]&.respond_to?(:each)
      doc[field] << element.string[0..ElasticsearchClient::MAX_KEYWORD_FIELD_LENGTH]
    end

    doc
  end

  ##
  # @return [void]
  #
  def assign_handle
    self.handle = Handle.create!(item: self)
    self.handle.reload # to read the suffix, which is autoincrementing
  end

  ##
  # Called at the end of the submission process.
  #
  def complete_submission
    raise "Item is not in a submitting state." unless submitting?
    update!(stage: self.primary_collection&.submissions_reviewed ?
                       Stages::SUBMITTED : Stages::APPROVED)
  end

  ##
  # @return [String] Comma-delimited list of all values of all `dc:creator`
  #                  elements.
  #
  def creators
    self.elements.select{ |e| e.name == "dc:creator" }.map(&:string).join(", ")
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
  # @return [Collection] The primary collection, if set; otherwise, any other
  #                      collection in the {collections} association.
  #
  def effective_primary_collection
    #noinspection RubyYardReturnMatch
    self.primary_collection || self.collections.first
  end

  ##
  # @return [Unit] The primary collection's primary unit, if set; otherwise,
  #                any other unit of any collection in the {collections}
  #                association.
  #
  def effective_primary_unit
    self.effective_primary_collection&.effective_primary_unit
  end

  ##
  # @return [SubmissionProfile] The primary collection's submission profile, o
  #                             the {SubmissionProfile#default default profile}
  #                             if not set.
  #
  def effective_submission_profile
    self.primary_collection&.effective_submission_profile || SubmissionProfile.default
  end

  ##
  # @return [Boolean] Whether all of the instance's associated Bitstreams have
  #                   been ingested into Medusa. Note that there is a delay
  #                   between the time a bitstream is submitted for ingest and
  #                   the time the ingest is complete, during which this method
  #                   will continue to return `false`.
  #
  def exists_in_medusa?
    self.bitstreams.where.not(medusa_uuid: nil).count > 0
  end

  ##
  # Uploads all of the instance's associated {Bitstream}s into Medusa.
  #
  # @return [void]
  #
  def ingest_into_medusa
    raise "Handle is not set" if self.handle.blank?
    self.bitstreams.where(submitted_for_ingest: false).each do |bitstream|
      begin
        bitstream.ingest_into_medusa
      rescue AlreadyExistsError
        # fine
      end
    end
  end

  ##
  # @return [String]
  #
  def label
    title
  end

  ##
  # @return [MetadataProfile] Effective metadata profile of the primary
  #                           {Collection}.
  #
  def metadata_profile
    primary_collection&.effective_metadata_profile
  end

  ##
  # @return [Unit]
  #
  def primary_unit
    #noinspection RubyYardReturnMatch
    self.primary_collection&.primary_unit
  end

  ##
  # N.B.: This is not a model validation because instances are allowed to be
  # missing elements during the submission process.
  #
  # @return [Boolean] Whether all {SubmissionProfileElement#required required
  #                   elements} in the {effective_submission_profile effective
  #                   submission profile} have been ascribed to the instance.
  #
  def required_elements_present?
    self.effective_submission_profile.elements.where(required: true).each do |spe|
      return false unless self.elements.find{ |ae| ae.name == spe.name &&
          (ae.string.present? || ae.uri.present?) }
    end
    true
  end

  ##
  # @return [Boolean] Whether {stage} is set to {Stages#SUBMITTED}.
  #
  def submitted?
    self.stage == Stages::SUBMITTED
  end

  ##
  # @return [Boolean] Whether {stage} is set to {Stages#SUBMITTING}.
  #
  def submitting?
    self.stage == Stages::SUBMITTING
  end

  ##
  # @return [Boolean] Whether {stage} is set to {Stages#WITHDRAWN}.
  #
  def withdrawn?
    self.stage == Stages::WITHDRAWN
  end


  private

  def email_after_submission
    if stage_was == Stages::SUBMITTING && stage == Stages::SUBMITTED
      IdealsMailer.item_submitted(self).deliver_now
    end
  end

  def restrict_in_archive_deletion
    raise "Archived items cannot be deleted" if self.exists_in_medusa?
  end

  def submission_includes_bitstreams
    if stage_was == Stages::SUBMITTING && stage == Stages::SUBMITTED &&
        bitstreams.length < 1
      errors.add(:bitstreams, "is empty")
    end
  end

  def submission_includes_required_elements
    if stage_was == Stages::SUBMITTING && stage == Stages::SUBMITTED &&
        !required_elements_present?
      errors.add(:elements, "is missing required elements")
    end
  end

  ##
  # @return [String]
  #
  def unit_and_collection_sort_key
    collection = self.effective_primary_collection
    unit       = collection&.effective_primary_unit
    item_title = self.title
    item_title = item_title.present? ? item_title : self.id
    [unit&.title, collection&.title, item_title].join(" ").strip
  end

end
