# frozen_string_literal: true

##
# Encapsulates a unit of intellectual content.
#
# # Creating, updating, and deleting
#
# Most creates and updates should be done through {CreateItemCommand}. This
# will ensure that an appropriate {Event} is created and associated with the
# instance. Deleting can still be done directly on the instance without use of
# a {Command}.
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
# * `stage`                 Lifecycle stage, whose value is one of the {Stages}
#                           constant values.
# * `submitter_id`          Foreign key to {User}.
# * `updated_at`            Managed by ActiveRecord.
#
# # Relationships
#
# * `bitstreams`         References all associated {Bitstream}s.
# * `collections`        References all owning {Collections}.
# * `current_embargoes`  References zero-to-many {Embargo}es.
# * `elements`           References zero-to-many {AscribedElement}s used to
#                        describe an instance.
# * `embargoes`          References zero-to-many {Embargo}es. (Some may be
#                        expired; see {current_embargoes}.)
# * `primary_collection` References the primary {Collection} in which the
#                        instance resides.
#
class Item < ApplicationRecord
  include Auditable
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
    EMBARGOES          = "o_embargoes"
    GROUP_BY_UNIT_AND_COLLECTION_SORT_KEY = "k_unit_collection_sort_key"
    ID                 = ElasticsearchIndex::StandardFields::ID
    INSTITUTION_KEY    = ElasticsearchIndex::StandardFields::INSTITUTION_KEY
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
      self.constants.map{ |c| self.const_get(c) }.sort
    end

    def self.label_for(value)
      self.constants.find{ |c| self.const_get(c) == value }&.to_s&.downcase
    end
  end

  has_many :bitstreams
  has_many :bitstream_authorizations
  has_many :collection_item_memberships
  has_many :collections, through: :collection_item_memberships
  has_many :elements, class_name: "AscribedElement"
  has_many :embargoes
  has_many :current_embargoes, -> { current }, class_name: "Embargo"
  has_many :events
  has_one :handle
  has_one :primary_collection_membership, -> { where(primary: true) },
          class_name: "CollectionItemMembership"
  has_one :primary_collection, through: :primary_collection_membership,
          class_name: "Collection", source: :collection
  belongs_to :submitter, class_name: "User", inverse_of: "submitted_items",
             optional: true

  before_save :email_after_submission
  before_destroy :restrict_in_archive_deletion

  validates :stage, inclusion: { in: Stages.all }
  validate :submission_includes_bitstreams,
           :submission_includes_required_elements

  breadcrumbs parent: :primary_collection, label: :title

  ##
  # @return [Enumerable<User>] All managers of all owning collections,
  #                            including the primary one.
  #
  def all_collection_managers
    bucket = Set.new
    collections.each do |col|
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
    collections.each do |col|
      bucket += col.submitting_users
    end
    bucket
  end

  ##
  # @return [Enumerable<Collections>] All owning collections, including their
  #                                   parents.
  #
  def all_collections
    bucket = Set.new
    self.collections.each do |collection|
      bucket << collection
      bucket += collection.all_parents
    end
    bucket
  end

  ##
  # @return [Enumerable<Unit>] All owning units, including their parents.
  #
  def all_units
    bucket = Set.new
    collections.each do |collection|
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
  # Sets {stage} to {Stages::APPROVED} and creates an associated
  # `dcterms:available` {AscribedElement} with a string value of the current
  # ISO-8601 date/time.
  #
  # @return [void]
  #
  def approve
    if self.stage != Stages::APPROVED
      self.stage        = Stages::APPROVED
      self.discoverable = true
      self.elements.build(registered_element: RegisteredElement.find_by_name("dcterms:available"),
                          string:             Time.now.iso8601)
    end
  end

  ##
  # @return [Boolean] Whether {stage} is set to {Stages#APPROVED}.
  #
  def approved?
    self.stage == Stages::APPROVED
  end

  ##
  # Overrides {Auditable#as_change_hash}.
  #
  def as_change_hash
    hash = super
    hash['stage'] = Stages::label_for(hash['stage'])
    # Add ascribed elements.
    # Because there may be multiple elements with the same name, we maintain a
    # map of name -> count pairs and append the count to the name if it is > 1.
    element_counts = {}
    self.elements.each do |element|
      if element_counts[element.name].present?
        element_counts[element.name] += 1
      else
        element_counts[element.name] = 1
      end
      key = "element:#{element.name}"
      key += "-#{element_counts[element.name]}" if element_counts[element.name] > 1
      hash["#{key}:string"] = element.string
      hash["#{key}:uri"]    = element.uri
    end
    # Add bitstreams.
    self.bitstreams.each do |bitstream|
      bitstream.as_change_hash.each do |k, v|
        hash["bitstream:#{bitstream.original_filename}:#{k}"] = v
      end
    end
    # Add embaroges.
    self.embargoes.each_with_index do |embargo, index|
      embargo.as_change_hash.each do |k, v|
        hash["embargo:#{index}:#{k}"] = v
      end
    end
    hash
  end

  ##
  # @return [Hash] Indexable JSON representation of the instance.
  #
  def as_indexed_json
    doc = {}
    doc[IndexFields::CLASS]              = self.class.to_s
    collections                          = self.collections
    doc[IndexFields::COLLECTION_TITLES]  = collections.map(&:title)
    doc[IndexFields::COLLECTIONS]        = collections.map(&:id)
    doc[IndexFields::CREATED]            = self.created_at.utc.iso8601
    doc[IndexFields::DISCOVERABLE]       = self.discoverable
    doc[IndexFields::EMBARGOES]          = self.current_embargoes.select(&:full_access).map(&:as_indexed_json)
    doc[IndexFields::GROUP_BY_UNIT_AND_COLLECTION_SORT_KEY] =
        self.unit_and_collection_sort_key
    units                                = self.all_units
    doc[IndexFields::INSTITUTION_KEY]    = units.first&.institution&.key
    doc[IndexFields::LAST_INDEXED]       = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED]      = self.updated_at.utc.iso8601
    doc[IndexFields::PRIMARY_COLLECTION] = self.primary_collection&.id
    doc[IndexFields::PRIMARY_UNIT]       = self.primary_unit&.id
    doc[IndexFields::STAGE]              = self.stage
    doc[IndexFields::SUBMITTER]          = self.submitter_id
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
  # Creates a new [Handle], assigns it to the instance, and creates an
  # associated `dcterms:identifier` [AscribedElement] with a URI value of the
  # handle URI.
  #
  # @return [void]
  # @raises [StandardError] if the instance already has a handle.
  #
  def assign_handle
    return if self.handle
    self.handle = Handle.create!(item: self)
    # Reload it in order to read the suffix, which is auto-incrementing.
    self.handle.reload
    # Assign a dcterms:identifier element with a URI value of the handle URI.
    self.elements.build(registered_element: RegisteredElement.find_by_name("dcterms:identifier"),
                        string:             self.handle.url,
                        uri:                self.handle.url)
  end

  ##
  # Updates the {stage} property and creates an associated
  # `dcterms:dateSubmitted` element with a string value of the current ISO-8601
  # date/time.
  #
  # @return [void]
  #
  def complete_submission
    if self.primary_collection&.submissions_reviewed
      self.update!(stage: Stages::SUBMITTED)
    else
      self.approve
    end
    # Assign a dcterms:dateSubmitted element with a string value of the current
    # ISO-8601 date/time.
    self.elements.build(registered_element: RegisteredElement.find_by_name("dcterms:dateSubmitted"),
                        string:             Time.now.iso8601)
  end

  ##
  # @return [String] Comma-delimited list of all values of all `dc:creator`
  #                  elements.
  #
  def creators
    self.elements.select{ |e| e.name == "dc:creator" }.map(&:string).join(", ")
  end

  ##
  # @param start_time [Time] Optional beginning of a time range.
  # @param end_time [Time]   Optional end of a time range.
  # @return [Integer]        Total download count of all attached bitstreams.
  #
  def download_count(start_time: nil, end_time: nil)
    items = self.bitstreams.
      joins(:events).
      where("events.event_type": Event::Type::DOWNLOAD)
    items = items.where("events.happened_at >= ?", start_time) if start_time
    items = items.where("events.happened_at <= ?", end_time) if end_time
    items.count
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
                WHERE i.id = $1
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
    self.effective_primary_collection&.primary_unit || self.collections.first.primary_unit
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
  # Uploads all of the instance's associated {Bitstream}s into Medusa. The
  # instance must already have a {handle} and the bitstreams must have
  # {permanent_key permanent keys}.
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
  # @return [Institution]
  #
  def institution
    primary_collection.primary_unit.institution
  end

  ##
  # @return [MetadataProfile] Effective metadata profile of the primary
  #                           {Collection}.
  #
  def metadata_profile
    primary_collection&.effective_metadata_profile
  end

  ##
  # @return [void]
  #
  def move_into_permanent_storage
    self.bitstreams.each(&:move_into_permanent_storage)
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
    unit       = collection&.primary_unit
    item_title = self.title
    item_title = item_title.present? ? item_title : self.id
    [unit&.title, collection&.title, item_title].join(" ").strip
  end

end
