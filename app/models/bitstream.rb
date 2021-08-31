##
# Binary file/object associated with an {Item}. The "bitstream" terminology
# comes from DSpace, which is what IDEALS used to be built on.
#
# The term "bitstream" is not exposed in the user interface. Throughout the UI,
# bitstreams are called files. (IR-109)
#
# # Media types
#
# The `Content-Type` header supplied by the client during the submission/upload
# process cannot be relied on to contain a useful, specific media type.
# Instead, {upload_to_staging} infers a media type from the {original_filename}
# extension during the initial upload to the staging area. This value may or
# may not be copied to the S3 object in staging, but it doesn't really matter
# because {media_type} is the "source of truth."
#
# Later, the S3 object in staging is ingested into Medusa, and Medusa will
# perform its own media type management, which is not very reliable. Again,
# {media_type} is the source of truth.
#
# When a media type cannot be inferred, {media_type} is set to `nil.` When the
# media type database is updated with more types, it is a good idea to update
# media types by running the `ideals:bitstreams:assign_media_types` rake task,
# which will infer media types for all bitstreams lacking one. See {FileFormat}
# for more information about the format database where media types are stored.
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
# * `bundle`                One of the {Bundle} constant values.
# * `created_at`:           Managed by ActiveRecord.
# * `dspace_id`:            `bitstream.internal_id` column value from
#                           IDEALS-DSpace. This is only relevant during
#                           migration out of that system and can be removed
#                           once migration is complete.
# * `exists_in_staging`:    Whether a corresponding object exists in the
#                           staging "area" (key prefix) of the application S3
#                           bucket.
# * `item_id`:              Foreign key to {Item}.
# * `length`:               Size in bytes.
# * `media_type`:           Media/MIME type.
# * `medusa_key`:           Full object key within the Medusa S3 bucket. Set
#                           only once the bitstream has been ingested into
#                           Medusa.
# * `medusa_uuid`:          UUID of the corresponding binary in the Medusa
#                           Collection Registry. Set only after the bitstream
#                           has been ingested.
# * `original_filename`:    Filename of the bitstream as submitted by the user.
# * `role`:                 One of the {Role} constant values indicating the
#                           minimum-privileged role required to access the
#                           instance.
# * `staging_key`:          Full object key in the application S3 bucket. May
#                           be set even though the bitstream does not exist in
#                           staging--check `exists_in_staging` to be sure.
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
  validates_format_of :media_type, with: /[\w+-]+\/[\w+-]+/, allow_blank: true
  validates_format_of :medusa_uuid,
                      with: /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/,
                      message: 'UUID is invalid',
                      allow_blank: true
  validates_inclusion_of :role, in: -> (value) { Role.all }
  validate :validate_staging_properties

  before_destroy :delete_derivatives, :delete_from_staging
  before_destroy :delete_from_medusa, if: -> { Rails.env.demo? }

  # This must be a location that Medusa is configured to monitor
  STAGING_KEY_PREFIX = "uploads"

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

    ##
    # @return [Enumerable<Integer>]
    #
    def self.all
      Bundle.constants.map { |c| Bundle.const_get(c) }
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
  # For use in testing only.
  #
  def self.create_bucket
    raise "Not going to create a bucket in this environment" unless
        %w(development test).include?(Rails.env)
    client = S3Client.instance
    bucket = ::Configuration.instance.aws[:bucket]
    unless S3Client.instance.bucket_exists?(bucket)
      client.create_bucket(bucket: bucket)
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
    bs = Bitstream.new(item:              item,
                       staging_key:       staging_key(item.id, filename),
                       original_filename: filename,
                       length:            length)
    bs.infer_media_type
    bs
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
  # Creates an associated {Event} representing a download.
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

  def delete_derivatives
    S3Client.instance.delete_objects(bucket:     ::Configuration.instance.aws[:bucket],
                                     key_prefix: derivative_key_prefix)
  end

  ##
  # Sends a message to Medusa to delete the corresponding object.
  #
  # This should only be done in the demo environment. The production Medusa
  # instance shouldn't even honor delete messages.
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
  # Deletes the corresponding object from the application S3 bucket.
  #
  def delete_from_staging
    return unless self.exists_in_staging
    S3Client.instance.delete_object(bucket: ::Configuration.instance.aws[:bucket],
                                    key:    self.staging_key)
  rescue Aws::S3::Errors::NotFound
    # That's OK
  ensure
    self.update!(exists_in_staging: false, staging_key: nil)
  end

  ##
  # @param region [Symbol]              `:full` or `:square`.
  # @param size [Integer]               Power-of-2 size constraint (128, 256,
  #                                     512, etc.)
  # @param content_disposition [Symbol] `:inline` or `:attachment`.
  # @param filename [String]            Used when `content_disposition` is
  #                                     `:attachment`.
  # @return [String] Pre-signed URL for a derivative image with the given
  #                  characteristics. If no such image exists, it is generated
  #                  automatically.
  # @raises [Aws::S3::Errors::NotFound]
  #
  def derivative_url(region:              :full,
                     size:                ,
                     content_disposition: :inline,
                     filename:            nil)
    unless has_representative_image?
      raise "Derivatives are not supported for this format."
    end
    if content_disposition == :attachment && filename.present?
      content_disposition = "attachment; filename=#{filename}"
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
                         bucket:                       bucket,
                         key:                          key,
                         response_content_disposition: content_disposition.to_s,
                         expires_in:                   1.hour.to_i)
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
  # @return [Boolean]
  #
  def has_representative_image?
    ext    = self.original_filename.split(".").last
    format = FileFormat.for_extension(ext)
    format ? (format.readable_by_vips == true) : false
  end

  ##
  # Updates {media_type} with a value based on the extension of
  # {original_filename}. The instance is not saved.
  #
  def infer_media_type
    ext = self.original_filename.split(".").last
    self.media_type = FileFormat.for_extension(ext)&.media_types&.first
  end

  ##
  # @raises [ArgumentError] if the bitstream does not have an ID or staging key.
  # @raises [AlreadyExistsError] if the bitstream already has a Medusa UUID.
  #
  def ingest_into_medusa
    raise ArgumentError, "Bitstream has not been saved yet" if self.id.blank?
    raise ArgumentError, "Bitstream's staging key is nil" if self.staging_key.blank?
    raise ArgumentError, "Bitstream's item does not have a handle" unless self.item.handle&.suffix&.present?
    raise AlreadyExistsError, "Bitstream has already been submitted for ingest" if self.submitted_for_ingest
    raise AlreadyExistsError, "Bitstream already exists in Medusa" if self.medusa_uuid.present?

    # The staging key is relative to STAGING_KEY_PREFIX because Medusa is
    # configured to look only within that prefix.
    staging_key_ = [self.item.id, self.original_filename].join("/")
    target_key   = self.class.medusa_key(self.item.handle.handle,
                                         self.original_filename)
    message = self.messages.build(operation:   Message::Operation::INGEST,
                                  staging_key: staging_key_,
                                  target_key:  target_key)
    message.save!
    message.send_message
    self.update!(submitted_for_ingest: true)
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
  # Writes the given IO to the staging "area" (key prefix) of the application
  # S3 bucket.
  #
  # @param io [IO]
  #
  def upload_to_staging(io)
    S3Client.instance.put_object(bucket: ::Configuration.instance.aws[:bucket],
                                 key:    self.staging_key,
                                 body:   io)
    self.update!(exists_in_staging: true)
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
    source_bucket = self.exists_in_staging ?
                      config.aws[:bucket] : config.medusa[:bucket]
    source_key    = self.exists_in_staging ? self.staging_key : self.medusa_key
    tempfile      = Tempfile.new("#{self.class}-#{self.id}")

    S3Client.instance.get_object(bucket:          source_bucket,
                                 key:             source_key,
                                 response_target: tempfile.path)
    tempfile
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
    config        = Configuration.instance
    target_bucket = config.aws[:bucket]
    target_key    = derivative_key(region: region, size: size, format: format)
    tempfile      = download_to_temp_file
    begin
      # crop options: none, attention, centre, entropy
      thumb_buf = Vips::Image.thumbnail(tempfile.path, size,
                                        crop: (region == :square) ? "attention" : "none")
      thumb_jpg = thumb_buf.write_to_buffer(".#{format}")
      io = StringIO.new(thumb_jpg)
      io.binmode

      S3Client.instance.put_object(bucket: target_bucket,
                                   key:    target_key,
                                   body:   io)
    ensure
      tempfile.unlink
    end
  end

  def validate_staging_properties
    if exists_in_staging && staging_key.blank?
      errors.add(:base, "Instance is marked as existing in staging, but its "\
          "staging key is blank.")
    end
  end

end
