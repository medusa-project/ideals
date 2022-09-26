##
# Binary file/object associated with an [Item]. The "bitstream" terminology
# comes from DSpace, which is what IDEALS used to be built on.
#
# The term "bitstream" is not exposed in the user interface. Throughout the UI,
# bitstreams are called files. (IR-109)
#
# # Storage locations
#
# When a file is first uploaded, it is stored in the application S3 bucket
# under `institutions/:key/staging/`, and {staging_key} is set on its
# corresponding instance. When it is approved, it is moved to a location under
# `institutions/:key/storage/`, and {permanent_key} is set on its corresponding
# instance. Also, a message is sent to Medusa to ingest it into the IDEALS file
# group. Upon receipt of a success message, {medusa_key} and {medusa_uuid} are
# set on its corresponding instance.
#
# # Formats/media types
#
# The `Content-Type` header supplied by the client during the submission/upload
# process cannot be relied on to contain a useful, specific media type.
# Instead, the {original_filename} extension is used by {format} to infer a
# [FileFormat], which may have one or more associated media types.
#
# Later, the S3 object in staging is ingested into Medusa, and Medusa will
# perform its own media type management, which is not very reliable. Again,
# {original_filename} is the "source of truth."
#
# When a format cannot be inferred, {format} will return `nil.` In this case it
# may be necessary to update the format database; see [FileFormat] for more
# information.
#
# # Derivative images
#
# The application supports image previews for some file types. If the return
# value of {has_representative_image?} is `true`, {derivative_url} can be used
# to obtain the URL of a derivative image with the given characteristics. The
# URL points to an image in the application S3 bucket, which is generated
# on-the-fly and cached.
#
# # Full text
#
# See [FullText].
#
# # Download statistics
#
# See [BitstreamsController] documentation.
#
# # Attributes
#
# * `bundle`                One of the [Bundle] constant values.
# * `bundle_position`       Zero-based position (order) of the bitstream
#                           relative to other bitstreams in the same bundle and
#                           attached to the same [Item].
# * `created_at`:           Managed by ActiveRecord.
# * `description`:          Description.
# * `dspace_id`:            `bitstream.internal_id` column value from
#                           DSpace. This is only relevant during migration out
#                           of DSpace and can be removed once migration is
#                           complete.
# * `full_text_checked_at`  Date/time that the bitstream's content was last
#                           checked for full text. When this is set,
#                           {full_text} may or may not contain anything, but
#                           when it's not set, it certainly doesn't. Only
#                           bitstreams in the {Bundle#CONTENT content bundle}
#                           in a supported format typically get checked.
# * `item_id`:              Foreign key to [Item].
# * `length`:               Size in bytes.
# * `medusa_key`:           Full object key within the Medusa S3 bucket. Set
#                           only once the bitstream has been ingested into
#                           Medusa.
# * `medusa_uuid`:          UUID of the corresponding binary in the Medusa
#                           Collection Registry. Set only after the bitstream
#                           has been ingested.
# * `original_filename`:    Filename of the bitstream as submitted by the user.
# * `permanent_key`:        Object key in the application S3 bucket, which is
#                           set after the owning [Item] has been approved.
# * `primary`               Whether the instance is the primary bitstream of
#                           the owning [Item]. An item may have zero or one
#                           primary bitstreams.
# * `role`:                 One of the [Role] constant values indicating the
#                           minimum-privileged role required to access the
#                           instance.
# * `staging_key`:          Object key in the application S3 bucket, which is
#                           set after the instance has been uploaded but before
#                           it has been approved.
# * `submitted_for_ingest`: Set to `true` after an ingest message has been sent
#                           to Medusa.
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

  before_save :ensure_primary_uniqueness
  after_save :ingest_into_medusa, if: -> {
    item.handle.present? && permanent_key.present? &&
      saved_change_to_permanent_key? && !submitted_for_ingest }
  after_save :read_full_text_async, if: -> {
    bundle == Bundle::CONTENT &&
    can_read_full_text? &&
    full_text_checked_at.blank? &&
    effective_key.present? &&
    (defined?(ActiveSupport::TestCase) != "constant" || ActiveSupport::TestCase.respond_to?(:seeding) && !ActiveSupport::TestCase.seeding?) &&
    !DspaceImporter.instance.running? }
  before_destroy :delete_derivatives, :delete_from_staging,
                 :delete_from_permanent_storage
  before_destroy :delete_from_medusa, if: -> { medusa_uuid.present? }

  before_create :shift_bundle_positions_before_create, unless: -> { DspaceImporter.instance.running? }
  before_update :shift_bundle_positions_before_update, unless: -> { DspaceImporter.instance.running? }
  after_destroy :shift_bundle_positions_after_destroy, unless: -> { DspaceImporter.instance.running? }

  LOGGER = CustomLogger.new(Bitstream)

  INSTITUTION_KEY_PREFIX = "institutions"

  ##
  # Contains constants corresponding to the allowed values of {bundle}.
  #
  class Bundle
    CONTENT         = 0
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
  # Creates a zip file containing the given bitstreams and places it in the
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
    Dir.mktmpdir do |tmpdir|
      bitstreams.each_with_index do |bs, index|
        tmpfile = bs.download_to_temp_file
        FileUtils.mv(tmpfile.path, File.join(tmpdir, bs.original_filename))
        task&.progress(index / bitstreams.length.to_f)
      end
      zip_filename = "files.zip"
      zip_pathname = File.join(tmpdir, zip_filename)
      # -j: don't record directory names
      # -r: recurse into directories
      `zip -jr "#{zip_pathname}" #{tmpdir}`

      # Upload the zip file into the application S3 bucket.
      File.open(zip_pathname, "r") do |file|
        # upload_file will automatically use the multipart API for files larger
        # than 15 MB. (S3 has a 5 GB limit when not using the multipart API,
        # which we are unlikely to reach, but you never know.)
        s3 = Aws::S3::Resource.new(S3Client.client_options)
        s3.bucket(::Configuration.instance.storage[:bucket]).
          object(dest_key).
          upload_file(file)
      end
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
                  length:            length)
  end

  ##
  # @param institution_key [String]
  # @param item_id [Integer]
  # @param filename [String]
  # @return [String]
  #
  def self.permanent_key(institution_key:, item_id:, filename:)
    [INSTITUTION_KEY_PREFIX, institution_key, "storage", item_id,
     filename].join("/")
  end

  ##
  # @param institution_key [String]
  # @param item_id [Integer]
  # @param filename [String]
  # @return [String]
  #
  def self.staging_key(institution_key:, item_id:, filename:)
    [INSTITUTION_KEY_PREFIX, institution_key, "uploads", item_id,
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
  # @param user_group [UserGroup]
  # @return [Boolean] Whether the given user group authorizes access to the
  #                   instance.
  #
  def authorized_by?(user_group)
    self.item.bitstream_authorizations.where(user_group: user_group).count > 0
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
    config = ::Configuration.instance
    bucket = config.storage[:bucket]
    key    = self.effective_key
    S3Client.instance.get_object(bucket: bucket, key: key).body
  end

  def delete_derivatives
    begin
      config = ::Configuration.instance
      S3Client.instance.delete_objects(bucket:     config.storage[:bucket],
                                       key_prefix: derivative_key_prefix)
    rescue Aws::S3::Errors::NoSuchBucket
      # This would hopefully only happen because of a test environment
      # misconfiguration. In any case, it's safe to assume that if the bucket
      # doesn't exist, there is nothing to delete.
    end
  end

  ##
  # Sends a message to Medusa to delete the corresponding object.
  #
  # This should only be done in the demo environment, if at all. The production
  # Medusa instance shouldn't even honor delete messages.
  #
  def delete_from_medusa
    return nil if self.medusa_uuid.blank?
    message = self.messages.build(operation:   Message::Operation::DELETE,
                                  medusa_uuid: self.medusa_uuid,
                                  medusa_key:  self.medusa_key)
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
    S3Client.instance.delete_object(bucket: ::Configuration.instance.storage[:bucket],
                                    key:    self.permanent_key)
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
    S3Client.instance.delete_object(bucket: ::Configuration.instance.storage[:bucket],
                                    key:    self.staging_key)
    self.update!(staging_key: nil)
  rescue Aws::S3::Errors::NotFound
    self.update!(staging_key: nil)
  end

  ##
  # @param region [Symbol] `:full` or `:square`.
  # @param size [Integer]  Power-of-2 size constraint (128, 256, 512, etc.)
  # @param generate_async [Boolean] Whether to generate the derivative (if
  #                                 necessary) asynchronously. If true, and the
  #                                 image has not already been generated, nil
  #                                 is returned.
  # @return [String] Pre-signed URL for a derivative image with the given
  #                  characteristics. If no such image exists, it is generated
  #                  automatically.
  # @raises [Aws::S3::Errors::NotFound]
  #
  def derivative_url(region: :full, size:, generate_async: false)
    unless has_representative_image?
      raise "Derivatives are not supported for this format."
    end
    client       = S3Client.instance
    bucket       = ::Configuration.instance.storage[:bucket]
    key          = derivative_key(region: region, size: size, format: :jpg)
    unless client.object_exists?(bucket: bucket, key: key)
      if generate_async
        GenerateDerivativeImageJob.perform_later(self, region, size, :jpg)
        return nil
      else
        generate_derivative(region: region, size: size, format: :jpg)
      end
    end

    aws_client = client.send(:get_client)
    signer     = Aws::S3::Presigner.new(client: aws_client)
    signer.presigned_url(:get_object,
                         bucket:     bucket,
                         key:        key,
                         expires_in: 1.hour.to_i)
  end

  ##
  # @return [Integer]
  #
  def download_count
    self.events.where(event_type: Event::Type::DOWNLOAD).count
  end

  ##
  # @return [Tempfile]
  #
  def download_to_temp_file
    config        = Configuration.instance
    source_bucket = config.storage[:bucket]
    source_key    = self.effective_key
    tempfile      = Tempfile.new("#{self.class}-#{self.id}")
    S3Client.instance.get_object(bucket:          source_bucket,
                                 key:             source_key,
                                 response_target: tempfile.path)
    tempfile
  end

  ##
  # This method is only used during migration out of DSpace.
  #
  # @return [String,nil] Path on the DSpace file system relative to the asset
  #                      store root.
  #
  def dspace_relative_path
    dspace_id.present? ? ["",
                          dspace_id[0..1],
                          dspace_id[2..3],
                          dspace_id[4..5],
                          dspace_id].join("/") : nil
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
      ext = self.original_filename&.split(".")&.last
      @format = FileFormat.for_extension(ext) if ext
    end
    @format
  end

  ##
  # @return [Boolean]
  #
  def has_representative_image?
    format = self.format
    format ? (format.readable_by_vips == true) : false
  end

  ##
  # @param force [Boolean] If true, the ingest occurs even if the instance has
  #                        already been submitted or already exists in Medusa.
  # @raises [ArgumentError] if the bitstream does not have an ID, permanent key,
  #                         or handle.
  # @raises [AlreadyExistsError] if the bitstream already has a Medusa UUID.
  #
  def ingest_into_medusa(force: false)
    raise ArgumentError, "Instance has not been saved yet" if self.id.blank?
    raise ArgumentError, "Permanent key is not set" if self.permanent_key.blank?
    raise ArgumentError, "Owning item does not have a handle" if !self.item.handle || self.item.handle&.suffix&.blank?
    unless force
      raise AlreadyExistsError, "Already submitted for ingest" if self.submitted_for_ingest
      raise AlreadyExistsError, "Already exists in Medusa" if self.medusa_uuid.present?
    end

    # The staging key (this is Medusa AMQP interface terminology, not
    # Bitstream terminology) is relative to PERMANENT_KEY_PREFIX because Medusa
    # is configured to look only within that prefix.
    staging_key = [self.item_id, self.original_filename].join("/")
    target_key  = self.class.medusa_key(self.item.handle.handle,
                                        self.original_filename)
    message     = self.messages.build(operation:   Message::Operation::INGEST,
                                      staging_key: staging_key,
                                      target_key:  target_key)
    message.save!
    message.send_message
    self.update_column(:submitted_for_ingest, true) # skip callbacks
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

  def move_into_permanent_storage
    client        = S3Client.instance
    bucket        = ::Configuration.instance.storage[:bucket]
    permanent_key = self.class.permanent_key(institution_key: self.institution.key,
                                             item_id:         self.item_id,
                                             filename:        self.original_filename)
    transaction do
      client.copy_object(copy_source: "/#{bucket}/#{self.staging_key}", # source bucket+key
                         bucket:      bucket,                           # destination bucket
                         key:         permanent_key)                    # destination key
      self.update!(permanent_key: permanent_key,
                   staging_key:   nil)
      self.delete_from_staging
    end
  end

  ##
  # @param content_disposition [String]
  # @return [String]
  #
  def presigned_url(content_disposition: "attachment")
    config = ::Configuration.instance
    bucket = config.storage[:bucket]
    key    = self.effective_key
    unless key
      raise IOError, "This bitstream has no corresponding storage object."
    end
    client       = S3Client.instance.send(:get_client)
    signer       = Aws::S3::Presigner.new(client: client)
    content_type = self.format&.media_types&.first || "application/octet-stream"
    signer.presigned_url(:get_object,
                         bucket:                       bucket,
                         key:                          key,
                         response_content_type:        content_type,
                         response_content_disposition: content_disposition,
                         expires_in:                   900)
  end

  ##
  # Scans the bitstream content for full text, assigns it to {full_text},
  # updates {full_text_checked_at}, and reindexes the owning [Item].
  #
  # @param force [Boolean] Whether to read full text even if it has already
  #                        been checked for.
  # @return [void]
  #
  def read_full_text(force: false)
    return if !force && full_text_checked_at.present?
    text = nil
    #noinspection RubyRedundantSafeNavigation,RubyCaseWithoutElseBlockInspection
    case self.format&.short_name
    when "PDF"
      infile  = download_to_temp_file
      outfile = Tempfile.new("full_text")
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
      self.update!(full_text_checked_at: Time.now) and return
    end
    text = StringUtils.utf8(text) # convert to UTF-8
    text.delete!("\u0000")        # strip null bytes
    changed = (text != self.full_text&.text)
    transaction do
      self.full_text&.destroy!
      self.create_full_text!(text: text) if text.present?
      self.update!(full_text_checked_at: Time.now)
    end
    self.item.reindex if changed
  end

  ##
  # Invokes an asynchronous job to call {read_full_text} in the background.
  #
  def read_full_text_async
    ReadFullTextJob.perform_later(self)
  end

  ##
  # For use by the `dspace:bitstreams:copy` rake task.
  #
  # @param file [String]
  #
  def upload_to_permanent(file)
    # upload_file will automatically use the multipart API for files larger
    # than 15 MB. (S3 has a 5 GB limit when not using the multipart API.)
    s3 = Aws::S3::Resource.new(S3Client.client_options)
    s3.bucket(::Configuration.instance.storage[:bucket]).
      object(self.permanent_key).
      upload_file(file)
  end

  ##
  # Writes the given IO to the staging "area" (key prefix) of the application
  # S3 bucket.
  #
  # @param io [IO]
  #
  def upload_to_staging(io)
    config = ::Configuration.instance
    S3Client.instance.put_object(bucket: config.storage[:bucket],
                                 key:    self.staging_key,
                                 body:   io)
  end


  private

  ##
  # @param region [Symbol] `:full` or `:square`.
  # @param size [Integer]  Size of a square to fit within.
  # @param format [Symbol] Format extension with no leading dot.
  # @return [String]
  #
  def derivative_key(region:, size:, format:)
    [derivative_key_prefix, region.to_s, size.to_s,
     "default.#{format}"].join("/")
  end

  def derivative_key_prefix
    [INSTITUTION_KEY_PREFIX, self.institution.key, "derivatives", self.id].join("/")
  end

  def ensure_primary_uniqueness
    if self.primary
      self.item.bitstreams.where.not(id: self.id).update_all(primary: false)
    end
  end

  ##
  # Downloads the object into a temp file, writes a derivative image into an
  # in-memory buffer, and saves it to the application S3 bucket.
  #
  # @param region [Symbol]
  # @param size [Integer]
  # @param format [Symbol]
  #
  def generate_derivative(region:, size:, format:)
    config          = Configuration.instance
    target_bucket   = config.storage[:bucket]
    target_key      = derivative_key(region: region, size: size, format: format)
    source_tempfile = nil
    deriv_path      = nil
    begin
      source_tempfile = download_to_temp_file
      if source_tempfile
        crop = (region == :square) ? "--crop centre" : ""
        # ruby-vips gem is also an option here, but I experienced hanging on
        # some images, so vipsthumbnail will do just as well.
        `vipsthumbnail #{source_tempfile.path} #{crop} --size #{size}x#{size} -o %s-#{region}-#{size}.#{format}`
        deriv_path = File.join(File.dirname(source_tempfile.path),
                               "#{File.basename(source_tempfile.path)}-#{region}-#{size}.#{format}")
        File.open(deriv_path, "rb") do |file|
          S3Client.instance.put_object(bucket: target_bucket,
                                       key:    target_key,
                                       body:   file)
        end
      end
    rescue => e
      LOGGER.warn("generate_derivative(): #{e}")
    ensure
      source_tempfile&.unlink
      FileUtils.rm(deriv_path) rescue nil
    end
  end

  ##
  # Increments the bundle positions of all bitstreams attached to the owning
  # [Item] that are greater than or equal to the position of this instance, in
  # order to make room for it.
  #
  def shift_bundle_positions_before_create
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

  ##
  # Updates the bundle positions of all bitstreams attached to the owning
  # [Item] to ensure that they are sequential.
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
  # [Item] to ensure that they are sequential and zero-based.
  #
  def shift_bundle_positions_after_destroy
    if self.item && self.destroyed?
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

end
