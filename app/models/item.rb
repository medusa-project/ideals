# frozen_string_literal: true

##
# Encapsulates a unit of intellectual content.
#
# # Creating, updating, and deleting
#
# Creates generally happen via {CreateItemCommand}, updates via
# {UpdateItemCommand}. This will ensure that an appropriate {Event} is created
# and associated with the instance. Deleting can still be done directly on the
# instance without use of a {Command}--although {Item#bury! burial} is often
# used instead.
#
# # Lifecycle
#
# An item typically proceeds through several "life stages", indicated by the
# {stage} attribute and documented in the {Stages} class. {Stages::APPROVED} is
# where most items spend most of their lives, but note that an approved item
# may still have one more associated {Embargo embargoes}.
#
# # Indexing
#
# See the documentation of {Indexed} for a detailed explanation of how indexing
# works.
#
# # Attributes
#
# * `created_at`              Managed by ActiveRecord.
# * `deposit_agreement`       The deposit agreement that was agreed to by the
#                             submitter at the time the item was created.
# * `institution_id`          Foreign key to {Institution}. An item's owning
#                             institution is the same as that of its
#                             {effective_primary_unit effective primary unit},
#                             but in some cases, such as during the submission
#                             process, it may be necessary to know the
#                             institution before a collection has been
#                             assigned. The rest of the time, this attribute is
#                             just a shortcut to avoid having to navigate that
#                             relationship.
# * `previous_stage`          Previous lifecycle stage. Updates automatically
#                             when {stage} changes.
# * `previous_stage_reason`   Previous lifecycle stage reason. Updates
#                             automatically when {stage} changes.
# * `stage`                   Lifecycle stage, whose value is one of the
#                             {Stages} constant values.
# * `stage_reason`            Reason for setting the {stage} attribute to its
#                             current value.
# * `submitter_id`            Foreign key to {User}.
# * `temp_embargo_kind`       Temporarily holds the embargo kind during the
#                             submission process. When the item is submitted, a
#                             full-fledged {Embargo} instance is attached to
#                             the {embargoes} relationship and this value is
#                             nullified. These temporary embargo-related
#                             columns are needed because the submission form
#                             saves an item after every form element change,
#                             whether or not enough information has been input
#                             to construct a complete/valid {Embargo} instance.
# * `temp_embargo_expires_at` Temporarily holds the embargo lift date during
#                             the submission process. (See
#                             {temp_embargo_kind}.)
# * `temp_embargo_reason`     Temporarily holds the embargo reason during the
#                             submission process. (See {temp_embargo_kind}.)
# * `temp_embargo_type`       Temporarily holds the embargo type during the
#                             submission process. This corresponds to the radio
#                             buttons in the access section of the submission
#                             form, and not with any property of {Embargo}.
#                             (See {temp_embargo_kind}.)
# * `updated_at`              Managed by ActiveRecord.
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
  include Handled
  include Indexed

  ##
  # Contains constants for all "technical" indexed fields. Additional dynamic
  # metadata fields may also be present.
  #
  class IndexFields
    ALL_ELEMENTS       = OpenSearchIndex::StandardFields::ALL_ELEMENTS
    CLASS              = OpenSearchIndex::StandardFields::CLASS
    COLLECTION_TITLES  = "k_collection_titles"
    COLLECTIONS        = "i_collection_ids"
    CREATED            = OpenSearchIndex::StandardFields::CREATED
    EMBARGOES          = "o_embargoes"
    FILENAMES          = "t_filenames"
    FULL_TEXT          = OpenSearchIndex::StandardFields::FULL_TEXT
    GROUP_BY_UNIT_AND_COLLECTION_SORT_KEY = "k_unit_collection_sort_key"
    HANDLE             = "k_handle"
    ID                 = OpenSearchIndex::StandardFields::ID
    INSTITUTION_KEY    = OpenSearchIndex::StandardFields::INSTITUTION_KEY
    INSTITUTION_NAME   = OpenSearchIndex::StandardFields::INSTITUTION_NAME
    LAST_INDEXED       = OpenSearchIndex::StandardFields::LAST_INDEXED
    LAST_MODIFIED      = OpenSearchIndex::StandardFields::LAST_MODIFIED
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
    # cycle, leaving behind only a row in the items table that facilitates
    # display of a tombstone record. The burial is reversible via
    # {Item#exhume!}.
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
  belongs_to :institution, optional: true
  belongs_to :submitter, class_name: "User", inverse_of: "submitted_items",
             optional: true

  before_save :email_after_submission, :prune_duplicate_elements
  before_update :set_previous_stage
  before_destroy :restrict_in_archive_deletion, :destroy_bitstreams

  validates :temp_embargo_kind, inclusion: { in: Embargo::Kind::all },
                                allow_blank: true
  validates :temp_embargo_expires_at, format: /\d{4}-\d{2}-\d{2}/,
                                      allow_blank: true
  validates :temp_embargo_type, inclusion: { in: %w(open institution closed) },
                                allow_blank: true
  validates :stage, inclusion: { in: Stages.all }
  validate :validate_exhume, if: -> { stage != Item::Stages::BURIED }
  validate :validate_submission_includes_bitstreams,
           :validate_submission_includes_required_elements
  validate :validate_primary_bitstream

  ##
  # Creates a zip file containing all of the bitstreams of all the given items
  # and uploads it to the application bucket under the given key. The files
  # within the zip file are organized by item handle, with the handle prefix as
  # the root directory, and each item's handle suffix as a subdirectory within.
  #
  # All of the given items should have the same effective metadata profile (the
  # one given).
  #
  # @param item_ids [Enumerable<Integer>]
  # @param metadata_profile [MetadataProfile]
  # @param dest_key [String] Destination key within the application bucket.
  # @param request_context [RequestContext]
  # @param include_csv_file [Boolean]
  # @param print_progress [Boolean]
  # @param task [Task] Optional.
  #
  def self.create_zip_file(item_ids:,
                           metadata_profile:,
                           dest_key:,
                           request_context:,
                           include_csv_file: true,
                           print_progress:   false,
                           task:             nil)
    now         = Time.now
    count       = item_ids.count
    raise ArgumentError, "No items provided" if count < 1
    progress    = print_progress ? Progress.new(count) : nil
    status_text = "Generating a zip file for #{count} items"
    task&.update!(indeterminate: false,
                  started_at:    now,
                  status_text:   status_text)
    begin
      uncached do
        Dir.mktmpdir do |tmpdir|
          stuffdir = File.join(tmpdir, "items")
          FileUtils.mkdir_p(stuffdir)

          if include_csv_file
            csv = CsvExporter.new.export_items(item_ids: item_ids,
                                               elements: metadata_profile.elements.map(&:name))
            File.write(File.join(stuffdir, "items.csv"), csv)
          end

          index = 0
          item_ids.each do |item_id|
            item = Item.find(item_id)
            item.bitstreams.where.not(permanent_key: nil).each do |bs|
              next unless BitstreamPolicy.new(request_context, bs).download?
              dest_dir = File.join(stuffdir, item.handle&.handle || "#{item.id}")
              FileUtils.mkdir_p(dest_dir)
              dest_path = File.join(dest_dir, bs.filename)
              ObjectStore.instance.get_object(key:             bs.permanent_key,
                                              response_target: dest_path)
              task&.progress(index / count.to_f)
              progress&.report(index, "Downloading files")
            end
            index += 1
          end

          # Zip them all up
          zip_filename = "Item_create_zip_file-#{SecureRandom.hex}.zip"
          zip_pathname = File.join(tmpdir, zip_filename)
          `cd #{tmpdir} && zip -vr #{zip_filename} .`

          # Upload the zip file into the application S3 bucket.
          File.open(zip_pathname, "r") do |file|
            ObjectStore.instance.put_object(key:  dest_key,
                                            file: file)
          end
        end
      end
    rescue => e
      task&.fail(detail:    e.message,
                 backtrace: e.backtrace)
      raise e
    else
      task&.succeed
    end
  end

  ##
  # Convenience method that returns all non-embargoed {Item}s, excluding
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
  # @return [Enumerable<User>] All administrators of all owning collections,
  #                            including the primary one.
  #
  def all_collection_admins
    bucket = Set.new
    collections.each do |col|
      bucket += col.administering_users
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
      bucket += unit.effective_administering_users
    end
    bucket
  end

  ##
  # Approves the instance by:
  #
  # * Setting {stage} to {Stages::APPROVED}
  # * Creating an associated {AscribedElement} with a string value of the
  #   current ISO 8601 timestamp.
  # * Natural-sorting bitstreams by filename
  # * Creating a license bitstream
  # * Moving all bitstreams into permanent storage
  # * Ingesting all bitstreams into Medusa
  #
  # N.B. this method may or may not be invoked by {complete_submission}.
  #
  # @return [void]
  # @see complete_submission
  #
  def approve
    self.stage = Stages::APPROVED
    reg_e      = self.institution.date_approved_element
    self.elements.build(registered_element: reg_e,
                        string:             Time.now.iso8601) if reg_e
    natural_sort_bitstreams
    create_license_bitstream if self.deposit_agreement.present?
    self.move_into_permanent_storage
    # A handle should always be present at this point, except in testing.
    if self.handle && self.institution.outgoing_message_queue.present?
      self.ingest_into_medusa
    end
    self.save!
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
    hash.delete("temp_embargo_kind")
    hash.delete("temp_embargo_expires_at")
    hash.delete("temp_embargo_reason")
    hash.delete("temp_embargo_type")
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
        hash["bitstream:#{bitstream.id}:#{k}"] = v
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
    doc[IndexFields::FILENAMES]          = self.bitstreams.map(&:filename)
    # N.B.: in AWS OpenSearch, the maximum document size depends on instance
    # size, but for our purposes is likely 10485760 bytes (10 MB). The length
    # may be exceeded either by one large bitstream's FullText, or many smaller
    # bitstreams' combined FullTexts. In either case it must be truncated.
    io         = StringIO.new
    max_length = 7000000 # leave some room for the rest of the document
    Bitstream.uncached do
      self.bitstreams.select{ |bs| bs.bundle == Bitstream::Bundle::CONTENT &&
                                   bs.full_text_checked_at.present? }.each do |bs|
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
    doc[IndexFields::HANDLE]             = self.handle&.handle
    units                                = self.all_units
    doc[IndexFields::INSTITUTION_KEY]    = self.institution&.key ||
      units.first&.institution&.key
    doc[IndexFields::INSTITUTION_NAME]    = self.institution&.name ||
      units.first&.institution&.name
    doc[IndexFields::LAST_INDEXED]       = Time.now.utc.iso8601
    doc[IndexFields::LAST_MODIFIED]      = self.updated_at.utc.iso8601
    doc[IndexFields::PRIMARY_COLLECTION] = self.primary_collection&.id
    doc[IndexFields::PRIMARY_UNIT]       = self.primary_unit&.id
    doc[IndexFields::STAGE]              = self.stage
    doc[IndexFields::SUBMITTER]          = self.submitter_id
    doc[IndexFields::UNIT_TITLES]        = units.map(&:title)
    doc[IndexFields::UNITS]              = units.map(&:id)

    # Index ascribed metadata elements into dynamic fields, and also
    # concatenate them together into the all-elements field.
    all_values = []
    self.elements.each do |asc_e|
      reg_e      = asc_e.registered_element
      field      = reg_e.indexed_field
      # The fields are all arrays in order to support multiple values.
      doc[field] = [] unless doc[field]&.respond_to?(:each)
      # Most element values are indexed as-is (with HTML tags stripped). But
      # values of date-type registered elements (which may be in forms like
      # "Month DD, YYYY") need to be normalized as ISO 8601.
      if reg_e.input_type == RegisteredElement::InputType::DATE
        date = asc_e.date
        if date && date.year < OpenSearchIndex::MAX_YEAR
          doc[field] << date.iso8601
        else
          field       = reg_e.indexed_text_field
          doc[field]  = [] unless doc[field]&.respond_to?(:each)
          doc[field] << Nokogiri::HTML(asc_e.string).text
        end
      else
        string      = Nokogiri::HTML(asc_e.string).text
        all_values << string
        doc[field] << string[0..OpenSearchIndex::MAX_KEYWORD_FIELD_LENGTH]
      end
    end
    doc[IndexFields::ALL_ELEMENTS] = all_values.join(" ")
    doc
  end

  ##
  # Overrides parent.
  #
  # Creates a new {Handle}, assigns it to the instance, and creates an
  # associated {AscribedElement} with a URI value of the handle URI.
  #
  # @return [void]
  # @raises [StandardError] if the instance already has a handle.
  #
  def assign_handle
    return if self.handle || !self.institution
    self.create_handle!
    reg_e = self.institution.handle_uri_element
    self.elements.build(registered_element: reg_e,
                        string:             self.handle.permanent_url,
                        uri:                self.handle.permanent_url).save! if reg_e
  end

  def breadcrumb_label
    self.title
  end

  def breadcrumb_parent
    self.primary_collection
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
  # Invoked when a user has finished submitting an item. A date-submitted
  # element is created with a string value of the current ISO-8601 timestamp.
  # Then, if the owning collection is not reviewing submissions, {approve} is
  # called. Otherwise, the {stage} property is set to {Stages::SUBMITTED}.
  #
  # @return [void]
  # @see approve
  #
  def complete_submission
    # Assign a date-submitted element with a string value of the current
    # ISO-8601 timestamp.
    reg_e = self.institution.date_submitted_element
    self.elements.build(registered_element: reg_e,
                        string:             Time.now.iso8601).save! if reg_e
    if self.primary_collection&.submissions_reviewed
      self.update!(stage: Stages::SUBMITTED)
    else
      self.approve
    end
  end

  ##
  # For use in testing only.
  #
  def delete_from_permanent_storage
    raise "This method only works in the test environment" unless Rails.env.test?
    self.bitstreams.each(&:delete_from_permanent_storage)
  end

  ##
  # Compiles monthly download counts for a given time span by querying the
  # `events` table.
  #
  # Note that {MonthlyItemDownloadCount#for_item} uses a different technique--
  # querying the monthly item download count reporting table--that is much
  # faster.
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
    result = self.class.connection.exec_query(sql, "SQL", values).to_a
    result[0..(result.length - 2)]
  end

  ##
  # @return [MetadataProfile] The effective primary collection's effective
  #         metadata profile. If there is no such profile, as in the case of
  #         e.g. a {Stages#SUBMITTING submitting item} that has not yet been
  #         assigned to a collection, the global metadata profile is returned.
  #
  def effective_metadata_profile
    self.effective_primary_collection&.effective_metadata_profile ||
      MetadataProfile.global
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
    self.effective_primary_collection&.primary_unit ||
      self.collections.first&.primary_unit
  end

  ##
  # @return [SubmissionProfile] The primary collection's effective submission
  #                             profile, if set; otherwise, the owning
  #                             institution's default submission profile.
  #
  def effective_submission_profile
    self.effective_primary_collection&.effective_submission_profile ||
      self.institution&.default_submission_profile
  end

  ##
  # @param user [User]
  # @param client_ip [String]
  # @param client_hostname [String]
  # @return [Boolean]
  #
  def embargoed_for?(user:, client_ip:, client_hostname:)
    self.current_embargoes.where(kind: Embargo::Kind::ALL_ACCESS).each do |embargo|
      return true if !user || !embargo.exempt?(user:            user,
                                               client_ip:       client_ip,
                                               client_hostname: client_hostname)
    end
    false
  end

  ##
  # @see bury!
  #
  def exhume!
    if stage == Item::Stages::BURIED
      transaction do
        update!(stage:        self.previous_stage || Item::Stages::APPROVED,
                stage_reason: self.previous_stage_reason)
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
    self.bitstreams.where.not(medusa_uuid: nil).exists?
  end

  def ingest_into_medusa
    return if self.institution.outgoing_message_queue.blank?
    raise "Cannot ingest into Medusa without a handle" unless self.handle
    self.bitstreams.
      select{ |b| b.permanent_key.present? }.
      each(&:ingest_into_medusa)
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
    self.bitstreams.
      select{ |b| b.staging_key.present? }.
      each(&:move_into_permanent_storage)
  end

  ##
  # Efficiently (without using ActiveRecord) obtains the owning entity IDs in
  # the model hierarchy.
  #
  # @return [Enumerable<Hash>] Enumerable of hashes with `collection_id`,
  #                            `unit_id`, and `institution_id` keys.
  #
  def owning_ids
    sql = "SELECT cim.collection_id, ucm.unit_id, u.institution_id
          FROM collection_item_memberships cim
          LEFT JOIN unit_collection_memberships ucm ON ucm.collection_id = cim.collection_id
          LEFT JOIN units u ON u.id = ucm.unit_id
          WHERE cim.item_id = $1
          ORDER BY cim.primary DESC, ucm.primary DESC;"
    values = [self.id]
    result = ActiveRecord::Base.connection.exec_query(sql, "SQL", values)
    # This will be nil for items not in a collection.
    result[0] ? result[0] : {
      'collection_id'  => nil,
      'unit_id'        => nil,
      'institution_id' => nil
    }
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
    b = self.bitstreams.find(&:primary)
    return b if b
    candidates = self.bitstreams.select{ |b| b.bundle == Bitstream::Bundle::CONTENT }
    b = candidates.
      sort_by{ |b| [b.bundle_position ? 0 : 1, b.bundle_position] }.
      find{ |b| b.has_representative_image? }
    return b if b
    candidates.
      sort{ |a, b|
        (a.filename.split(".").last.downcase == "pdf" ? "0" : "zzz") <=>
        b.filename.split(".").last.downcase }.
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

  ##
  # In DSpace, a bitstream representing the deposit agreement that was agreed
  # to at the time an item was created was ascribed to it. This bitstream was
  # named `license.txt` and contained the text of the deposit agreement. This
  # app instead tracks the deposit agreement in the deposit_agreement column,
  # which is really the source-of-truth for this information, and should be
  # perfectly sufficient, but it was desired [definitely not by me--ed.] to
  # continue this behavior of attaching a license.txt bitstream to items
  # anyway.
  #
  # We add the bitstream only after the instance's stage has changed to
  # approved. This prevents us from having to filter it out of the files table
  # in the submission form, and keeps this whole "feature" contained to this
  # method so that it will be easier to remove at some point.
  #
  include ActionView::Helpers::TextHelper
  def create_license_bitstream
    raise "Instance must be approved" if stage != Stages::APPROVED
    raise "Deposit agreement is empty" if deposit_agreement.empty?
    return if self.bitstreams.find{ |b| b.filename == "license.txt" }
    transaction do
      agreement = self.deposit_agreement.strip
      if agreement.start_with?("<") # is it HTML?
        doc  = Kramdown::Document.new(agreement, input: "html")
        text = doc.to_kramdown
      else
        text = agreement
      end
      text = word_wrap(text)
      bs   = self.bitstreams.build(filename:          "license.txt",
                                   original_filename: "license.txt",
                                   bundle:            Bitstream::Bundle::LICENSE,
                                   length:            text.bytesize,
                                   staging_key: Bitstream.staging_key(
                                     institution_key: self.institution.key,
                                     item_id:         self.id,
                                     filename:        "license.txt"))
      bs.upload_to_staging(text)
    end
  end

  ##
  # Calls {destroy} on each dependent {Bitstream}. We can't rely on the
  # cascading foreign key because it doesn't trigger callbacks.
  #
  def destroy_bitstreams
    self.bitstreams.each(&:destroy!)
  end

  def email_after_submission
    # This ivar helps prevent duplicate sends.
    if !@email_sent_after_submission &&
        stage_was == Stages::SUBMITTING &&
        stage == Stages::SUBMITTED
      IdealsMailer.item_submitted(self).deliver_later
      if effective_primary_collection&.submissions_reviewed
        IdealsMailer.item_requires_review(self).deliver_later
      end
      @sent_email_after_submission = true
    end
  end

  ##
  # Natural-sorts attached bitstreams by filename.
  #
  def natural_sort_bitstreams
    filenames = self.bitstreams.map(&:filename)
    NaturalSort.sort!(filenames)
    self.bitstreams.each do |bs|
      bs.update!(bundle_position: filenames.index(bs.filename))
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

  def set_previous_stage
    if stage_changed?
      self.previous_stage        = self.stage_was
      self.previous_stage_reason = self.stage_reason_was
      # Nil this out if the stage changed but the reason didn't, to ensure that
      # it reflects the last stage change only.
      self.stage_reason          = nil unless stage_reason_changed?
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

  ##
  # Ensures that at least one owning collection is not buried when the stage
  # changes from {Stages::BURIED} to something else.
  #
  def validate_exhume
    if stage_was == Stages::BURIED && stage != Stages::BURIED &&
      collections.where.not(buried: true).count == 0
      errors.add(:base, "This item cannot be undeleted, as all of its "\
                        "owning collections are deleted.")
    end
  end

  def validate_primary_bitstream
    primary_count = self.bitstreams.count(&:primary)
    if primary_count > 1
      errors.add(:bitstreams, "has more than one primary bitstream")
    end
  end

  def validate_submission_includes_bitstreams
    if stage_was == Stages::SUBMITTING && stage == Stages::SUBMITTED &&
        bitstreams.length < 1
      errors.add(:bitstreams, "is empty")
    end
  end

  def validate_submission_includes_required_elements
    if stage_was == Stages::SUBMITTING && stage == Stages::SUBMITTED &&
        !required_elements_present?
      errors.add(:elements, "is missing required elements")
    end
  end

end
