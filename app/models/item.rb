# frozen_string_literal: true

##
# Encapsulates a unit of intellectual content.
#
# # Creating, updating, and deleting
#
# Most creates and updates should be done through [CreateItemCommand]. This
# will ensure that an appropriate [Event] is created and associated with the
# instance. Deleting can still be done directly on the instance without use of
# a [Command].
#
# # Lifecycle
#
# An item proceeds through several "life stages", indicated by the {stage}
# attribute and documented in the [Stages] class.
#
# # Indexing
#
# See the documentation of [Indexed] for a detailed explanation of how indexing
# works.
#
# # Attributes
#
# * `created_at`              Managed by ActiveRecord.
# * `stage`                   Lifecycle stage, whose value is one of the
#                             [Stages] constant values.
# * `stage_reason`            Reason for setting the {stage} attribute to its
#                             current value.
# * `submitter_id`            Foreign key to {User}.
# * `temp_embargo_kind`       Temporarily holds the embargo kind during the
#                             submission process. When the item is submitted, a
#                             full-fledged [Embargo] instance is attached to
#                             the {embargoes} relationship and this value is
#                             nullified. These temporary embargo-related
#                             columns are needed because the submission form
#                             saves an item after every form element change,
#                             whether or not enough information has been input
#                             to construct a complete/valid [Embargo] instance.
# * `temp_embargo_expires_at` Temporarily holds the embargo lift date during
#                             the submission process. (See
#                             {temp_embargo_kind}.)
# * `temp_embargo_reason`     Temporarily holds the embargo reason during the
#                             submission process. (See {temp_embargo_kind}.)
# * `temp_embargo_type`       Temporarily holds the embargo type during the
#                             submission process. This corresponds to the radio
#                             buttons in the access section of the submission
#                             form, and not with any property of [Embargo].
#                             (See {temp_embargo_kind}.)
# * `updated_at`              Managed by ActiveRecord.
#
# # Relationships
#
# * `bitstreams`         References all associated [Bitstream]s.
# * `collections`        References all owning [Collections].
# * `current_embargoes`  References zero-to-many [Embargo]es.
# * `elements`           References zero-to-many [AscribedElement]s used to
#                        describe an instance.
# * `embargoes`          References zero-to-many [Embargo]es. (Some may be
#                        expired; see {current_embargoes}.)
# * `primary_collection` References the primary [Collection] in which the
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
    EMBARGOES          = "o_embargoes"
    FILENAMES          = "t_filenames"
    FULL_TEXT          = ElasticsearchIndex::StandardFields::FULL_TEXT
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
    # An item that has been withdrawn by an administrator.
    WITHDRAWN  = 400

    ##
    # An item that has been "functionally deleted" at any point in its life
    # cycle, leaving behind only a row in the items table that facilitates display of
    # a tombstone record. The burial is reversible via {Item#exhume!}.
    BURIED = 500

    def self.all
      self.constants.map{ |c| self.const_get(c) }.sort
    end

    def self.label_for(value)
      self.constants.find{ |c| self.const_get(c) == value }&.to_s&.downcase
    end
  end

  has_many :all_access_embargoes, -> { current && all_access }, class_name: "Embargo"
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

  before_save :email_after_submission, :prune_duplicate_elements
  before_update :set_stage_reason
  before_destroy :restrict_in_archive_deletion

  validates :temp_embargo_kind, inclusion: { in: Embargo::Kind::all },
                                allow_blank: true
  validates :temp_embargo_expires_at, format: /\d{4}-\d{2}-\d{2}/,
                                      allow_blank: true
  validates :temp_embargo_type, inclusion: { in: %w(open uofi closed) },
                                allow_blank: true
  validates :stage, inclusion: { in: Stages.all }
  validate :validate_exhumed, if: -> { stage != Item::Stages::BURIED }
  validate :validate_submission_includes_bitstreams,
           :validate_submission_includes_required_elements
  validate :validate_primary_bitstream

  breadcrumbs parent: :primary_collection, label: :title

  ##
  # Convenience method that returns all non-embargoed [Item]s, excluding
  # download embargoes.
  #
  # @return [ActiveRecord::Relation<Item>]
  #
  def self.non_embargoed
    Item.left_outer_joins(:embargoes).
      where("(embargoes.perpetual != true OR embargoes.perpetual IS NULL) "\
            "AND (embargoes.expires_at < NOW() OR embargoes.expires_at IS NULL)").
      where("embargoes.kind != ? OR embargoes.kind IS NULL", Embargo::Kind::ALL_ACCESS)
  end

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
  # `dcterms:available` [AscribedElement] with a string value of the current
  # ISO-8601 timestamp.
  #
  # @return [void]
  #
  def approve
    self.stage = Stages::APPROVED
    unless self.elements.find{ |e| e.name == "dcterms:available" }
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
    doc[IndexFields::EMBARGOES]          = self.current_embargoes.
        select{ |e| e.kind == Embargo::Kind::ALL_ACCESS }.
        map(&:as_indexed_json)
    doc[IndexFields::FILENAMES]          = self.bitstreams.map(&:original_filename)
    # N.B.: on AWS, the maximum document size depends on ES instance size, but
    # for our purposes is likely 10485760 bytes (10 MB). Full text can
    # sometimes exceed this, so we must truncate it. The length may be exceeded
    # either by one large bitstream's FullText, or many smaller bitstreams'
    # FullText.
    io         = StringIO.new
    max_length = 7000000 # bytes; leave some room for the rest of the document
    Bitstream.uncached do
      self.bitstreams.select{ |bs| bs.full_text_checked_at.present? }.each do |bs|
        text_obj = bs.full_text
        io      << text_obj.text.delete("\000") if text_obj
        break if io.length > max_length
      end
    end
    # N.B.: truncate() will actually pad the string if it is shorter than
    # max_length.
    io.truncate(max_length) if io.length > max_length
    doc[IndexFields::FULL_TEXT]          = io.string
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

    # Index ascribed metadata elements into dynamic fields, consulting the
    # equivalent element in the metadata profile to check whether it should be
    # indexed or not.
    profile = self.effective_metadata_profile
    self.elements.each do |element|
      pe = profile.elements.find{ |pe| pe.name == element.name }
      if !pe || pe.indexed
        field = element.registered_element.indexed_field
        doc[field] = [] unless doc[field]&.respond_to?(:each)
        doc[field] << element.string[0..ElasticsearchClient::MAX_KEYWORD_FIELD_LENGTH]
      end
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
  # @return [Boolean] Whether {stage} is set to {Stages#BURIED}.
  #
  def buried?
    self.stage == Stages::BURIED
  end

  def bury!
    if stage != Item::Stages::BURIED
      transaction do
        update!(stage: Item::Stages::BURIED)
        Event.create!(event_type:     Event::Type::DELETE,
                      item:           self,
                      before_changes: self,
                      after_changes:  nil,
                      description:    "Item deleted.")
      end
    end
  end

  ##
  # Updates the {stage} property and creates an associated
  # `dcterms:date:submitted` element with a string value of the current
  # ISO-8601 timestamp.
  #
  # @return [void]
  #
  def complete_submission
    if self.primary_collection&.submissions_reviewed
      self.update!(stage: Stages::SUBMITTED)
    else
      self.approve
    end
    # Assign a dcterms:date:submitted element with a string value of the
    # current ISO-8601 timestamp.
    self.elements.build(registered_element: RegisteredElement.find_by_name("dc:date:submitted"),
                        string:             Time.now.iso8601)
    assign_handle
  end

  ##
  # For use in testing only.
  #
  def delete_from_permanent_storage
    raise "This method only works in the test environment" unless Rails.env.test?
    self.bitstreams.each(&:delete_from_permanent_storage)
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
    end_time   = Time.now.utc unless end_time
    raise ArgumentError, "start_time > end_time" if start_time > end_time
    start_series = "#{start_time.year}-#{start_time.month}-01"
    end_series   = Date.civil(end_time.year, end_time.month, -1) # last day of month

    sql = "SELECT mon.month, coalesce(e.count, 0) AS dl_count
        FROM generate_series('#{start_series}'::timestamp,
                             '#{end_series}'::timestamp, interval '1 month') AS mon(month)
        LEFT JOIN (
            SELECT date_trunc('Month', e.happened_at) as month,
                   COUNT(DISTINCT e.id) AS count
            FROM events e
                LEFT JOIN bitstreams b on e.bitstream_id = b.id
                LEFT JOIN items i ON b.item_id = i.id
            WHERE i.id = $1
                AND e.event_type = $2
                AND e.happened_at >= $3
                AND e.happened_at <= $4
            GROUP BY month
        ) e ON mon.month = e.month
        ORDER BY mon.month;"
    values = [self.id, Event::Type::DOWNLOAD, start_time, end_time]
    self.class.connection.exec_query(sql, "SQL", values)
  end

  ##
  # @return [MetadataProfile] The effective primary collection's metadata
  #                           profile, or the {MetadataProfile#default default
  #                           profile} if not set.
  #
  def effective_metadata_profile
    self.effective_primary_collection&.effective_metadata_profile ||
      MetadataProfile.default
  end

  ##
  # @return [Collection] The primary collection, if set; otherwise, any other
  #                      collection in the {collections} association.
  #
  def effective_primary_collection
    #noinspection RubyMismatchedReturnType
    self.primary_collection || self.collections.first
  end

  ##
  # @return [Unit] The primary collection's primary unit, if set; otherwise,
  #                any other unit of any collection in the {collections}
  #                association.
  #
  def effective_primary_unit
    #noinspection RubyMismatchedReturnType
    self.effective_primary_collection&.primary_unit || self.collections.first&.primary_unit
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
  # @see bury!
  #
  def exhume!
    if stage == Item::Stages::BURIED
      transaction do
        update!(stage: Item::Stages::APPROVED)
        Event.create!(event_type:     Event::Type::UNDELETE,
                      item:           self,
                      before_changes: nil,
                      after_changes:  self,
                      description:    "Item undeleted.")
      end
    end
  end

  ##
  # @return [Boolean] Whether all of the instance's associated Bitstreams have
  #                   been ingested into Medusa. Note that there is a delay
  #                   between the time a bitstream is submitted for ingest and
  #                   the time the ingest is complete, during which this method
  #                   will return `false`.
  #
  def exists_in_medusa?
    self.bitstreams.where.not(medusa_uuid: nil).count > 0
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
    #noinspection RubyMismatchedReturnType
    self.primary_collection&.primary_unit
  end

  ##
  # @return [Bitstream]
  #
  def representative_bitstream
    self.bitstreams.find(&:primary) ||
      self.bitstreams.
        select{ |b| b.bundle == Bitstream::Bundle::CONTENT }.
        sort{ |a, b|
          (a.original_filename.split(".").last.downcase == 'pdf' ? 'a' : 'zzz') <=>
          b.original_filename.split(".").last.downcase }.
        first
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
  # Sets the primary collection, ensuring that any other collections are made
  # non-primary. If the item does not already belong to the collection, it is
  # added.
  #
  # @param collection [Collection]
  # @return [void]
  #
  def set_primary_collection(collection)
    memberships = self.collection_item_memberships
    memberships.select{ |m| m.primary == true && m.collection_id != collection.id }.
      each{ |m| m.update!(primary: false) }
    primary_membership = memberships.find{ |m| m.collection_id == collection.id }
    if primary_membership
      primary_membership.update!(primary: true)
    else
      self.collection_item_memberships.build(collection: collection,
                                             primary:    true)
      self.save!
    end
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
    if stage_was == Stages::SUBMITTING && stage == Stages::SUBMITTED &&
        effective_primary_collection&.submissions_reviewed
      IdealsMailer.item_submitted(self).deliver_now
    end
  end

  ##
  # Destroys associated [AscribedElement]s that have the same {string}, {uri},
  # and {registered_element} attribute as another element.
  #
  def prune_duplicate_elements
    all_elements    = self.elements.to_a
    unique_elements = []
    all_elements.each do |e|
      unless unique_elements.find{ |ue| e.string == ue.string &&
          e.uri == ue.uri &&
          e.registered_element_id == ue.registered_element_id }
        unique_elements << e
      end
    end
    (all_elements - unique_elements).each(&:destroy!)
  end

  def restrict_in_archive_deletion
    raise "Archived items cannot be deleted" if self.exists_in_medusa?
  end

  ##
  # Nils out {stage_reason} if the stage changed but the reason didn't. This
  # ensures that {stage_reason} reflects the last stage change only
  #
  def set_stage_reason
    self.stage_reason = nil if self.stage_changed? && !self.stage_reason_changed?
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

  ##
  # Ensures that at least one owning collection is not buried when the stage
  # changes from {Stages::BURIED} to something else.
  #
  def validate_exhumed
    if stage_was == Stages::BURIED && stage != Stages::BURIED &&
      collections.where.not(buried: true).count == 0
      errors.add(:base, "This item cannot be undeleted, as all of its "\
                        "owning collections are deleted.")
      throw(:abort)
    end
  end

  def validate_primary_bitstream
    primary_count = self.bitstreams.count(&:primary)
    if primary_count > 1
      errors.add(:bitstreams, "has more than one primary bitstream")
      throw(:abort)
    end
  end

  def validate_submission_includes_bitstreams
    if stage_was == Stages::SUBMITTING && stage == Stages::SUBMITTED &&
        bitstreams.length < 1
      errors.add(:bitstreams, "is empty")
      throw(:abort)
    end
  end

  def validate_submission_includes_required_elements
    if stage_was == Stages::SUBMITTING && stage == Stages::SUBMITTED &&
        !required_elements_present?
      errors.add(:elements, "is missing required elements")
      throw(:abort)
    end
  end

end
