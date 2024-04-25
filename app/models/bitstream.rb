# frozen_string_literal: true

##
# Binary file/object associated with an {Item}. The "bitstream" terminology
# comes from DSpace, which is what IDEALS used to be built on, but "file" is
# used in the user interface.
#
# # Uploads
#
# See {BitstreamsController} documentation.
#
# # Downloads
#
# See {BitstreamsController} documentation.
#
# ## Statistics
#
# See {BitstreamsController} documentation.
#
# # Storage locations
#
# When a file is first uploaded, it is stored in the application S3 bucket
# under `institutions/:key/staging/:item_id`, and {staging_key} is set on its
# corresponding instance. When it is approved, it is moved to a location under
# `institutions/:key/storage/:item_handle`, and {permanent_key} is set on its
# corresponding instance. Also, a message is sent to Medusa to ingest it into
# the IDEALS file group. Upon receipt of a success message, {medusa_key} and
# {medusa_uuid} are set on its corresponding instance.
#
# It would be simpler to use just one storage location, like
# `institutions/:key/storage/`, but the keys under that prefix are all handles,
# which items may not receive until they are submitted.
#
# Filenames can be changed at any time by updating the {filename} property.
# ActiveRecord callbacks will handle all the work of maintaining consistency
# with application and preservation storage.
#
# # Formats/media types
#
# The `Content-Type` header supplied by the client during the submission/upload
# process cannot be relied on to contain a useful, specific media type.
# Instead, the {filename} extension is used by {format} to infer a
# {FileFormat}, which may have one or more associated media types.
#
# Later, the S3 object in staging is ingested into Medusa, and Medusa will
# perform its own media type management, which is not very reliable. Again,
# {filename} is the "source of truth."
#
# When a format cannot be inferred, {format} will return `nil.` In this case it
# may be necessary to update the {FileFormat format database}.
#
# # Preservation
#
# Bitstreams are ingested into Medusa automatically depending on several
# conditions--see the `ingest_into_medusa` `before_save` callback.
#
# # Derivative images
#
# The application supports image previews for some file types. If the return
# value of {has_representative_image?} is `true`, {DerivativeGenerator} can be
# used to generate derivative images and return their URLs.
#
# # Full text
#
# See {FullText}.
#
# # Attributes
#
# * `archived_files`:       Contains a serialized array of archived files
#                           contained within zip-format bitstreams, in the
#                           format returned by {#archived_files}.
# * `bundle`:               One of the {Bundle} constant values.
# * `bundle_position`:      Zero-based position (order) of the bitstream
#                           relative to other bitstreams in the same bundle and
#                           attached to the same {Item}.
# * `created_at`:           Managed by ActiveRecord.
# * `derivative_generation_attempted_at`: The last time derivative generation
#                           was attempted.
# * `derivative_generation_succeeded`: Whether the last derivative generation
#                           attempt was successful. This flag makes it possible
#                           to avoid trying over and over when derivative
#                           generation fails.
# * `description`:          Description.
# * `filename`:             Filename of the bitstream. This may be (and usually
#                           is) the same as {original_filename}, but may be
#                           different if the bitstream/file was renamed after
#                           ingest.
# * `full_text_checked_at`: Date/time that the bitstream's content was last
#                           checked for full text. When this is set,
#                           {full_text} may or may not contain anything, but
#                           when it's not set, it definitely doesn't. Only
#                           bitstreams in the {Bundle#CONTENT content bundle}
#                           in a supported format typically get checked.
# * `item_id`:              Foreign key to {Item}.
# * `length`:               Size in bytes.
# * `medusa_key`:           Full object key within the Medusa S3 bucket. Set
#                           only once the bitstream has been ingested into
#                           Medusa.
# * `medusa_uuid`:          UUID of the corresponding binary in the Medusa
#                           Collection Registry. Set only after the bitstream
#                           has been ingested.
# * `original_filename`:    Filename of the bitstream as submitted by the user.
#                           This may or may not be the same as {filename}.
# * `permanent_key`:        Object key in the application S3 bucket, which is
#                           set after the owning {Item} has been approved.
# * `primary`:              Whether the instance is the primary bitstream of
#                           the owning {Item}. An item may have zero or one
#                           primary bitstreams.
# * `role`:                 One of the {Role} constant values indicating the
#                           minimum-privileged role required to access the
#                           instance.
# * `staging_key`:          Object key in the application S3 bucket, which is
#                           set after the instance has been uploaded but before
#                           it has been approved.
# * `updated_at`:           Managed by ActiveRecord.
#
class Bitstream < ApplicationRecord
  include Auditable

  belongs_to :item
  has_one :full_text
  has_many :events
  has_many :messages

  validates_inclusion_of :bundle, in: -> (value) { Bundle.all }
  validates_numericality_of :length, greater_than_or_equal_to: 0, allow_blank: true
  validates_format_of :medusa_uuid,
                      with: /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/,
                      message: 'UUID is invalid',
                      allow_blank: true
  validates_inclusion_of :role, in: -> (value) { Role.all }

  before_save :populate_filename
  before_save :ensure_primary_uniqueness
  before_save :rename_storage_object, if: -> {
    ((filename_changed? && filename_was.present?) ||
      (staging_key_changed? && staging_key_was.present?) ||
      (permanent_key_changed? && permanent_key_was.present?)) &&
      (staging_key.present? || permanent_key.present?)
  }
  before_save :delete_from_medusa, if: -> {
    filename_changed? &&
      medusa_key.present? &&
      institution.outgoing_message_queue.present?
  }
  after_save :ingest_into_medusa, if: -> { # depends on a database ID
    permanent_key.present? &&
      saved_change_to_permanent_key? &&
      item.handle.present? &&
      institution.outgoing_message_queue.present?
  }
  after_save :reindex_owning_item, if: -> {
      filename_changed?
  }
  after_save :read_full_text_async, if: -> {
    bundle == Bundle::CONTENT &&
    can_read_full_text? &&
    full_text_checked_at.blank? &&
    effective_key.present? &&
    (defined?(ActiveSupport::TestCase) != "constant")
  }
  before_destroy :delete_derivatives, :delete_from_staging,
                 :delete_from_permanent_storage
  before_destroy :delete_from_medusa, if: -> { medusa_uuid.present? }

  before_create :shift_bundle_positions_before_create
  before_update :shift_bundle_positions_before_update
  after_destroy :shift_bundle_positions_after_destroy

  validate :validate_original_filename_immutability
  validate :validate_unique_filename

  serialize :archived_files, coder: JSON

  LOGGER = CustomLogger.new(Bitstream)

  ##
  # Contains constants corresponding to the allowed values of {bundle}.
  #
  class Bundle
    CONTENT         = 0
    # Legacy name for the content bundle in DSpace, still used by Vireo
    ORIGINAL        = 0
    TEXT            = 1
    LICENSE         = 2
    METADATA        = 3
    CONVERSION      = 4
    THUMBNAIL       = 5
    ARCHIVE         = 6
    SOURCE          = 7
    BRANDED_PREVIEW = 8
    NOTES           = 9
    SWORD           = 10

    ##
    # @return [Enumerable<Integer>]
    #
    def self.all
      Bundle.constants.map { |c| Bundle.const_get(c) }
    end

    ##
    # @param string [String] Constant name.
    # @return [Integer] One of the constant values.
    #
    def self.for_string(string)
      Bundle.const_get(string.to_sym)
    end

    ##
    # @param value [Integer] One of the constant values.
    # @return [String] English label for the value.
    #
    def self.label(value)
      return "Content" if value == 0
      label = Bundle.constants
          .find{ |c| Bundle.const_get(c) == value }
          .to_s
          .split("_")
          .map(&:capitalize)
          .join(" ")
      if label.present?
        return label
      else
        raise ArgumentError, "No bundle with value #{value}"
      end
    end
  end

  ##
  # Creates a zip file containing the given bitstreams and uploads it to the
  # application bucket under the given key.
  #
  # @param bitstreams [Enumerable<Bitstream>] Bitstreams to include in the zip
  #                                           file.
  # @param dest_key [String] Destination key within the application bucket.
  # @param item_id [Integer] Optional.
  # @param task [Task] Optional.
  #
  def self.create_zip_file(bitstreams:,
                           dest_key:,
                           item_id:    nil,
                           task:       nil)
    status_text  = "Generating #{bitstreams.length}-item zip file"
    status_text += " for item #{item_id}" if item_id
    task&.update!(indeterminate: false,
                  started_at:    Time.now,
                  status_text:   status_text)
    # We should be able to use a block with mktmpdir, but when using an EFS
    # filesystem, we get an error about "directory not empty"...
    tmpdir = Dir.mktmpdir
    begin
      bitstreams.each_with_index do |bs, index|
        tmpfile = bs.download_to_temp_file
        FileUtils.mv(tmpfile.path, File.join(tmpdir, bs.filename))
        task&.progress(index / bitstreams.length.to_f)
      end
      zip_filename = "files.zip"
      zip_pathname = File.join(tmpdir, zip_filename)
      # -j: don't record directory names
      # -r: recurse into directories
      `zip -jr "#{zip_pathname}" #{tmpdir}`

      # Upload the zip file into the application S3 bucket.
      File.open(zip_pathname, "r") do |file|
        ObjectStore.instance.put_object(key:  dest_key,
                                        file: file)
      end
    ensure
      FileUtils.rm_rf(tmpdir)
    end
  end

  ##
  # Computes a destination Medusa key based on the given arguments. The key is
  # relative to the file group key prefix, which is known only by Medusa, so
  # the return value will be different than the value of {medusa_key}, which
  # includes the prefix.
  #
  # @param handle [String]
  # @param filename [String]
  # @return [String]
  # @raises ArgumentError if either argument is blank.
  #
  def self.medusa_key(handle, filename)
    raise ArgumentError, "Handle is blank" if handle.blank?
    raise ArgumentError, "Filename is blank" if filename.blank?
    [handle, filename.gsub('/', '')].join("/")
  end

  ##
  # Creates a new instance that is not yet persisted. Call {upload_to_staging}
  # on the returned instance to upload data to the corresponding location, and
  # then invoke {save} on the instance.
  #
  # @param item [Item]
  # @param filename [String]
  # @param length [Integer]
  # @return [Bitstream] New instance.
  #
  def self.new_in_staging(item:, filename:, length:)
    Bitstream.new(item:              item,
                  staging_key:       staging_key(institution_key: item.institution.key,
                                                 item_id:         item.id,
                                                 filename:        filename),
                  original_filename: filename,
                  filename:          filename,
                  length:            length)
  end

  ##
  # @param institution_key [String]
  # @param item_id [Integer]
  # @param filename [String]
  # @return [String]
  #
  def self.permanent_key(institution_key:, item_id:, filename:)
    [ObjectStore::INSTITUTION_KEY_PREFIX, institution_key, "storage", item_id,
     filename].join("/")
  end

  ##
  # @param institution_key [String]
  # @param item_id [Integer]
  # @param filename [String]
  # @return [String]
  #
  def self.staging_key(institution_key:, item_id:, filename:)
    [ObjectStore::INSTITUTION_KEY_PREFIX, institution_key, "uploads", item_id,
     filename].join("/")
  end

  ##
  # Creates an associated [Event] representing a download, and increments the
  # relevant count values in the download reporting tables.
  #
  # @param user [User] Optional.
  #
  def add_download(user: nil)
    self.events.build(event_type:  Event::Type::DOWNLOAD,
                      institution: self.institution,
                      description: "Download",
                      happened_at: Time.now,
                      user:        user).save!
    owning_ids     = self.item.owning_ids
    institution_id = owning_ids['institution_id']
    unit_id        = owning_ids['unit_id']
    collection_id  = owning_ids['collection_id']
    return unless institution_id && unit_id && collection_id
    MonthlyItemDownloadCount.increment(self.item)
    MonthlyCollectionItemDownloadCount.increment(collection_id)
    MonthlyUnitItemDownloadCount.increment(unit_id)
    MonthlyInstitutionItemDownloadCount.increment(institution_id)
  end

  ##
  # For zip files, returns a list of hashes with information about the files
  # contained in the zip file. For all other formats, returns an empty list.
  #
  # The result is cached.
  #
  # @return [Enumerable<Hash>] List of hashes with `:name`, `:length`, and
  #                            `:date` keys, ordered by name.
  #
  def archived_files
    return [] if self.format.media_type != "application/zip"
    value = self.read_attribute(:archived_files)
    return value.map{ |l| l.symbolize_keys } if value

    tempfile = download_to_temp_file
    files    = ZipUtils.archived_files(tempfile.path)
    self.update_column(:archived_files, files)
    files
  ensure
    tempfile&.unlink
  end

  ##
  # @param user_group [UserGroup]
  # @return [Boolean] Whether the given user group authorizes access to the
  #                   instance.
  #
  def authorized_by?(user_group)
    self.item.bitstream_authorizations.where(user_group: user_group).exists?
  end

  ##
  # @return [Boolean] Whether {read_full_text full text can be read}.
  #
  def can_read_full_text?
    %w(PDF Text).include?(self.format&.short_name)
  end

  ##
  # @return [IO] New instance for reading.
  #
  def data
    ObjectStore.instance.get_object(key: self.effective_key)
  end

  def delete_derivatives
    DerivativeGenerator.new(self).delete_derivatives
  end

  ##
  # Sends a message to Medusa to delete the corresponding object.
  #
  # @param institution [Institution] Optional institution whose queue to send
  #                                  to. Defaults to {institution}.
  #
  def delete_from_medusa(institution: nil)
    return nil if self.medusa_uuid.blank?
    # N.B.: MessageHandler will nil out medusa_uuid and medusa_key upon success.
    # See inline comment in ingest_into_medusa() for an explanation of this
    institution ||= self.institution
    message = self.messages.build(operation:   Message::Operation::DELETE,
                                  medusa_uuid: self.medusa_uuid,
                                  medusa_key:  self.medusa_key,
                                  institution: institution)
    message.save!
    message.send_message
  end

  ##
  # Deletes the corresponding object from the permanent storage area of the
  # application S3 bucket.
  #
  # There would probably never be a reason to do this, except for testing.
  #
  def delete_from_permanent_storage
    return if self.permanent_key.blank?
    ObjectStore.instance.delete_object(key: self.permanent_key)
    self.update!(permanent_key: nil)
  rescue Aws::S3::Errors::NotFound
    self.update!(permanent_key: nil)
  end

  ##
  # Deletes the corresponding object from the staging area of the application
  # S3 bucket.
  #
  def delete_from_staging
    return if self.staging_key.blank?
    ObjectStore.instance.delete_object(key: self.staging_key)
    self.update!(staging_key: nil)
  rescue Aws::S3::Errors::NotFound
    self.update!(staging_key: nil)
  end

  ##
  # @return [Integer]
  #
  def download_count
    self.events.where(event_type: Event::Type::DOWNLOAD).count
  end

  ##
  # N.B. The returned instance must be unlinked/deleted manually.
  #
  # @return [Tempfile]
  #
  def download_to_temp_file
    source_key = self.effective_key
    raise "Instance has no effective key" unless source_key
    ext        = self.format&.extensions&.first || "tmp"
    tempfile   = Tempfile.new(["#{self.class}-#{self.id}-download_to_temp_file", ".#{ext}"])
    begin
      ObjectSpace.undefine_finalizer(tempfile)
      ObjectStore.instance.get_object(key:             source_key,
                                      response_target: tempfile.path)
    rescue => e
      tempfile.unlink
      raise e
    else
      tempfile
    end
  end

  ##
  # @return [String, nil] The permanent key, if present; otherwise the staging
  #                       key, if present; otherwise nil.
  #
  def effective_key
    return self.permanent_key if self.permanent_key.present?
    return self.staging_key if self.staging_key.present?
    nil
  end

  ##
  # @return [FileFormat, nil]
  #
  def format
    unless @format
      ext     = self.filename&.split(".")&.last
      @format = FileFormat.for_extension(ext) if ext
    end
    @format
  end

  ##
  # Returns whether the instance has full text without loading the associated
  # {FullText} instance (because it may be very large).
  #
  # @return [Boolean]
  #
  def has_full_text?
    return false if full_text_checked_at.blank?
    FullText.where(bitstream_id: self.id).exists?
  end

  ##
  # @return [Boolean]
  #
  def has_representative_image?
    self.format&.derivative_generator&.present? || false
  end

  ##
  # @raises [ArgumentError] if the bitstream does not have an ID or permanent
  #                         key, or if its owning item does not have a handle.
  #
  def ingest_into_medusa
    return if self.institution.outgoing_message_queue.blank?
    raise ArgumentError, "Instance has not been saved yet" if self.id.blank?
    raise ArgumentError, "Permanent key is not set" if self.permanent_key.blank?
    raise ArgumentError, "Owning item does not have a handle" if !self.item.handle || self.item.handle&.suffix&.blank?

    # The staging key (this is Medusa AMQP interface terminology, not
    # Bitstream terminology) is relative to the permanent key prefix because
    # Medusa is configured to look only within that prefix.
    staging_key = [self.item_id, self.filename].join("/")
    target_key  = self.class.medusa_key(self.item.handle.handle, self.filename)
    message     = self.messages.build(operation:   Message::Operation::INGEST,
                                      staging_key: staging_key,
                                      target_key:  target_key,
                                      institution: self.institution)
    message.save!
    message.send_message
  end

  ##
  # @return [Institution] The institution to which the instance belongs.
  #
  def institution
    self.item.institution
  end

  ##
  # Shortcut to accessing the first media type of the {format}.
  #
  # @return [String, nil]
  #
  def media_type
    self.format&.media_types&.first
  end

  ##
  # @return [String] Full URL of the instance's corresponding Medusa file, or
  #                  nil if does not exist in Medusa.
  #
  def medusa_url
    if self.medusa_uuid
      [::Configuration.instance.medusa[:base_url].chomp("/"),
       "uuids",
       self.medusa_uuid].join("/")
    end
  end

  ##
  # Moves the associated S3 object from the staging area of the bucket to the
  # permanent area, and updates {staging_key} and {permanent_key}.
  #
  def move_into_permanent_storage
    raise "Staging key is blank" if self.staging_key.blank?
    store         = ObjectStore.instance
    permanent_key = self.class.permanent_key(institution_key: self.institution.key,
                                             item_id:         self.item_id,
                                             filename:        self.filename)
    store.move_object(source_key: self.staging_key,
                      target_key: permanent_key)
    self.update_column(:permanent_key, permanent_key) # skip callbacks
    self.update_column(:staging_key, nil)             # skip callbacks
  end

  ##
  # @param content_disposition [String]
  # @return [String]
  #
  def presigned_download_url(content_disposition: "attachment")
    key = self.effective_key
    unless key
      raise IOError, "This bitstream has no corresponding storage object."
    end
    content_type = self.format&.media_types&.first || "application/octet-stream"
    ObjectStore.instance.presigned_download_url(key:                          key,
                                                response_content_type:        content_type,
                                                response_content_disposition: content_disposition)
  end

  ##
  # @return [String]
  #
  def presigned_upload_url
    if self.item.stage >= Item::Stages::APPROVED
      key = self.class.permanent_key(institution_key: self.institution.key,
                                     item_id:         self.item_id,
                                     filename:        self.filename)
      self.update!(permanent_key: key)
    else
      key = self.class.staging_key(institution_key: self.institution.key,
                                   item_id:         self.item_id,
                                   filename:        self.filename)
      self.update!(staging_key: key)
    end
    ObjectStore.instance.presigned_upload_url(key: key, expires_in: 30)
  end

  ##
  # Scans the bitstream content for full text, assigns it to {full_text},
  # updates {full_text_checked_at}, and reindexes the owning {Item}.
  #
  # @param force [Boolean] Whether to read full text even if it has already
  #                        been checked for.
  # @return [void]
  #
  def read_full_text(force: false)
    return if !force && full_text_checked_at.present?
    text = nil
    #noinspection RubyRedundantSafeNavigation
    case self.format&.short_name
    when "PDF"
      infile  = download_to_temp_file
      outfile = Tempfile.new("#{self.class}.read_full_text")
      begin
        # pdftotext is part of the poppler or xpdf package.
        `pdftotext -q #{infile.path} #{outfile.path}`
        text = File.read(outfile.path)
      ensure
        infile.close
        outfile.close
        infile.unlink
        outfile.unlink
      end
    when "Text"
      text = self.data.read
    else
      self.update_column(:full_text_checked_at, Time.now) and return
    end
    text = StringUtils.utf8(text) # convert to UTF-8
    text.delete!("\u0000")        # strip null bytes
    changed = (text != self.full_text&.text)
    transaction do
      self.full_text&.destroy!
      self.create_full_text!(text: text) if text.present?
      self.update_column(:full_text_checked_at, Time.now)
    end
    self.item.reindex if changed
  end

  ##
  # Invokes an asynchronous job to call {read_full_text} in the background.
  #
  def read_full_text_async
    task = Task.create!(name: ReadFullTextJob.to_s)
    ReadFullTextJob.perform_later(bitstream: self, task: task)
  end

  ##
  # @return [Boolean]
  #
  def submitted_for_ingest?
    self.messages.where(operation: Message::Operation::INGEST).exists?
  end

  ##
  # @param file [String]
  #
  def upload_to_permanent(file)
    ObjectStore.instance.put_object(key:  self.permanent_key,
                                    path: file)
    self.update!(length: File.size(file))
  end

  ##
  # Writes the given IO to the staging "area" (key prefix) of the application
  # S3 bucket.
  #
  # This is used mainly for testing, as uploads normally are directly into the
  # bucket using presigned URLs (see the documentation of
  # {BitstreamsController}).
  #
  # @param io [IO]
  #
  def upload_to_staging(io)
    ObjectStore.instance.put_object(key: self.staging_key,
                                    io:  io)
    self.update!(length: io.size)
  end


  private

  def ensure_primary_uniqueness
    if self.primary
      self.item.bitstreams.
        where.not(id: self.id).
        update_all(primary: false)
    end
  end

  ##
  # Sets {filename} to the value of {original_filename} if it is nil, and vice
  # versa.
  #
  def populate_filename
    self.filename ||= self.original_filename
    self.original_filename ||= self.filename
  end

  def reindex_owning_item
    self.item&.reindex
  end

  ##
  # `before_save` callback that renames the corresponding storage object.
  #
  def rename_storage_object
    if self.permanent_key_was.present? && self.permanent_key.present?
      target_key = nil
      if self.permanent_key != self.permanent_key_was
        target_key = self.permanent_key
      elsif self.filename != self.filename_was
        target_key = self.class.permanent_key(institution_key: self.institution.key,
                                              item_id:         self.item_id,
                                              filename:        self.filename)
      end
      if target_key
        ObjectStore.instance.move_object(source_key: self.permanent_key_was,
                                         target_key: target_key)
        self.update_column(:permanent_key, target_key) # skip callbacks
      end
    elsif self.staging_key_was.present? && self.staging_key.present?
      target_key = nil
      if self.staging_key != self.staging_key_was
        target_key = self.staging_key
      elsif self.filename != self.filename_was
        target_key = self.class.staging_key(institution_key: self.institution.key,
                                            item_id:         self.item_id,
                                            filename:        self.filename)
      end
      if target_key
        ObjectStore.instance.move_object(source_key: self.staging_key_was,
                                         target_key: target_key)
        self.update_column(:staging_key, target_key) # skip callbacks
      end
    end
  end

  ##
  # Increments the bundle positions of all bitstreams attached to the owning
  # {Item} that are greater than or equal to the position of this instance, in
  # order to make room for it.
  #
  def shift_bundle_positions_before_create
    if self.bundle_position
      transaction do
        self.item.bitstreams.
          where(bundle: self.bundle).
          where("bundle_position >= ?", self.bundle_position).each do |b|
          # update_column skips callbacks, which would cause this method to be
          # called recursively.
          b.update_column(:bundle_position, b.bundle_position + 1)
        end
      end
    end
  end

  ##
  # Updates the bundle positions of all bitstreams attached to the owning
  # {Item} to ensure that they are sequential.
  #
  def shift_bundle_positions_before_update
    if self.bundle_position_changed? && self.item
      position = 0
      transaction do
        self.item.bitstreams.
          where(bundle: self.bundle).
          where.not(id: self.id).
          order(:bundle_position).each do |b|
          position += 1 if position == self.bundle_position
          # update_column skips callbacks, which would cause this method to
          # be called recursively.
          b.update_column(:bundle_position, position)
          position += 1
        end
      end
    end
  end

  ##
  # Updates the bundle positions of all bitstreams attached to the owning
  # {Item} to ensure that they are sequential and zero-based.
  #
  def shift_bundle_positions_after_destroy
    if self.bundle_position && self.item && self.destroyed?
      transaction do
        self.item.bitstreams.
          where(bundle: self.bundle).
          order(:bundle_position).each_with_index do |bitstream, position|
          # update_column skips callbacks, which would cause this method to be
          # called recursively.
          bitstream.update_column(:bundle_position, position) if bitstream.bundle_position != position
        end
      end
    end
  end

  ##
  # Ensures that {original_filename}, once set, cannot be changed.
  #
  def validate_original_filename_immutability
    if self.original_filename_changed? && self.original_filename_was.present?
      errors.add(:original_filename, "cannot be changed")
    end
  end

  ##
  # Ensures that {filename} cannot be changed to the same as another bitstream
  # attached to the same {Item}.
  def validate_unique_filename
    return unless filename_changed?
    self.item.bitstreams.reject{ |bs| bs == self }.each do |bs|
      if bs.filename == filename
        errors.add(:filename, "cannot be the same as another file attached "\
                              "to the same item")
      end
    end
  end

end
