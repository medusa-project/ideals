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
# under {STAGING_KEY_PREFIX}, and {staging_key} is set on its corresponding
# instance. When it is approved, it is moved to a location under
# {PERMANENT_KEY_PREFIX}, and {permanent_key} is set on its corresponding
# instance. Also, a message is sent to Medusa to ingest it into the IDEALS file
# group. Upon receipt of a success message, {medusa_key} is set on its
# corresponding instance.
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
# may be necessary to update the format database; see {FileFormat} for more
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
# # Attributes
#
# * `bundle`                One of the [Bundle] constant values.
# * `created_at`:           Managed by ActiveRecord.
# * `description`:          Description.
# * `dspace_id`:            `bitstream.internal_id` column value from
#                           IDEALS-DSpace. This is only relevant during
#                           migration out of that system and can be removed
#                           once migration is complete.
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
  after_save :ingest_into_medusa, if: -> { permanent_key.present? && saved_change_to_permanent_key? && !submitted_for_ingest }
  before_destroy :delete_derivatives, :delete_from_staging
  before_destroy :delete_from_medusa, if: -> { medusa_uuid.present? }

  ##
  # Bitstreams are initially uploaded to a location under this key prefix.
  #
  STAGING_KEY_PREFIX = "uploads"

  ##
  # Bitstreams are moved under this key prefix when they are approved.
  # Medusa must be configured to monitor this location.
  #
  PERMANENT_KEY_PREFIX = "storage"

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
                  staging_key:       staging_key(item.id, filename),
                  original_filename: filename,
                  length:            length)
  end

  ##
  # @param item_id [Integer]
  # @param filename [String]
  # @return [String]
  #
  def self.permanent_key(item_id, filename)
    [PERMANENT_KEY_PREFIX, item_id, filename].join("/")
  end

  ##
  # @param item_id [Integer]
  # @param filename [String]
  # @return [String]
  #
  def self.staging_key(item_id, filename)
    [STAGING_KEY_PREFIX, item_id, filename].join("/")
  end

  ##
  # Creates an associated [Event] representing a download.
  #
  # @param user [User] Optional.
  #
  def add_download(user: nil)
    self.events.build(event_type:  Event::Type::DOWNLOAD,
                      description: "Download",
                      user:        user).save!
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
  # @return [IO] New instance for reading.
  #
  def data
    config = ::Configuration.instance
    bucket = config.aws[:bucket]
    key    = self.effective_key
    S3Client.instance.get_object(bucket: bucket, key: key).body.read
  end

  def delete_derivatives
    begin
      S3Client.instance.delete_objects(bucket:     ::Configuration.instance.aws[:bucket],
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
    raise "This is not supported in production" if Rails.env.production?
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
    S3Client.instance.delete_object(bucket: ::Configuration.instance.aws[:bucket],
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
    S3Client.instance.delete_object(bucket: ::Configuration.instance.aws[:bucket],
                                    key:    self.staging_key)
    self.update!(staging_key: nil)
  rescue Aws::S3::Errors::NotFound
    self.update!(staging_key: nil)
  end

  ##
  # @param region [Symbol] `:full` or `:square`.
  # @param size [Integer]  Power-of-2 size constraint (128, 256, 512, etc.)
  # @return [String] Pre-signed URL for a derivative image with the given
  #                  characteristics. If no such image exists, it is generated
  #                  automatically.
  # @raises [Aws::S3::Errors::NotFound]
  #
  def derivative_url(region: :full, size:)
    unless has_representative_image?
      raise "Derivatives are not supported for this format."
    end
    client = S3Client.instance
    bucket = ::Configuration.instance.aws[:bucket]
    key    = derivative_key(region: region, size: size, format: :jpg)
    unless client.object_exists?(bucket: bucket, key: key)
      generate_derivative(region: region, size: size, format: :jpg)
    end

    aws_client = client.send(:get_client)
    signer = Aws::S3::Presigner.new(client: aws_client)
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
  # This method is only used during migration out of IDEALS-DSpace. It can be
  # removed afterwards.
  #
  # @return [String,nil] Path on the IDEALS-DSpace file system relative to the
  #                      asset store root.
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
      ext = self.original_filename.split(".").last
      @format = FileFormat.for_extension(ext)
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
    bucket        = ::Configuration.instance.aws[:bucket]
    permanent_key = self.class.permanent_key(self.item_id,
                                             self.original_filename)
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
    bucket = config.aws[:bucket]
    key    = self.effective_key
    unless key
      raise IOError, "This bitstream has no corresponding storage object."
    end
    client = S3Client.instance.send(:get_client)
    signer = Aws::S3::Presigner.new(client: client)
    signer.presigned_url(:get_object,
                         bucket:                       bucket,
                         key:                          key,
                         response_content_disposition: content_disposition,
                         expires_in:                   900)
  end

  ##
  # For use only by the `ideals_dspace:copy` rake task. After migration, this
  # method can be removed.
  #
  # @param io [IO]
  #
  def upload_to_permanent(io) # TODO: remove this after migration out of IDEALS-DSpace
    S3Client.instance.put_object(bucket: ::Configuration.instance.aws[:bucket],
                                 key:    self.permanent_key,
                                 body:   io)
  end

  ##
  # Writes the given IO to the staging "area" (key prefix) of the application
  # S3 bucket.
  #
  # @param io [IO]
  #
  def upload_to_staging(io)
    S3Client.instance.put_object(bucket: ::Configuration.instance.aws[:bucket],
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
    "derivatives/#{self.id}"
  end

  ##
  # @return [Tempfile]
  #
  def download_to_temp_file
    config        = Configuration.instance
    source_bucket = config.aws[:bucket]
    source_key    = self.effective_key
    tempfile      = Tempfile.new("#{self.class}-#{self.id}")
    S3Client.instance.get_object(bucket:          source_bucket,
                                 key:             source_key,
                                 response_target: tempfile.path)
    tempfile
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
    target_bucket   = config.aws[:bucket]
    target_key      = derivative_key(region: region, size: size, format: format)
    source_tempfile = download_to_temp_file
    begin
      crop = (region == :square) ? "--crop centre" : ""
      # ruby-vips gem is also an option here, but I experienced an inexplicable
      # hanging issue on some images, so vipsthumbnail will do just as well.
      `vipsthumbnail #{source_tempfile.path} #{crop} --size #{size}x#{size} -o %s-#{region}-#{size}.#{format}`
      deriv_path = File.join(File.dirname(source_tempfile.path),
                             "#{File.basename(source_tempfile.path)}-#{region}-#{size}.#{format}")
      File.open(deriv_path, "rb") do |file|
        S3Client.instance.put_object(bucket: target_bucket,
                                     key:    target_key,
                                     body:   file)
      end
    ensure
      source_tempfile.unlink
      FileUtils.rm(deriv_path) rescue nil
    end
  end

end
