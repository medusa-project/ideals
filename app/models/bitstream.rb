##
# Binary file/object associated with an {Item}. The "bitstream" terminology
# comes from DSpace, which is what IDEALS used to be built on.
#
# The term "bitstream" is not exposed in the user interface. Throughout the UI,
# bitstreams are called files. (IR-109)
#
# # Attributes
#
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
# * `staging_key`:          Full object key in the application S3 bucket. May
#                           be set even though the bitstream does not exist in
#                           staging--check `exists_in_staging` to be sure.
# * `submitted_for_ingest`: Set to `true` after an ingest message has been sent
#                           to Medusa.
# * `updated_at`:           Managed by ActiveRecord.
#
class Bitstream < ApplicationRecord
  belongs_to :item
  has_many :messages

  validates_numericality_of :length, greater_than_or_equal_to: 0, allow_blank: true
  validates_format_of :media_type, with: /[\w+-]+\/[\w+-]+/, allow_blank: true
  validates_format_of :medusa_uuid,
                      with: /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/,
                      message: 'UUID is invalid',
                      allow_blank: true

  validate :validate_staging_properties

  before_destroy :delete_from_staging
  before_destroy :delete_from_medusa, if: -> { Rails.env.demo? }

  # This must be a location that Medusa is configured to monitor
  STAGING_KEY_PREFIX = "uploads"

  ##
  # For use in testing only.
  #
  def self.create_bucket
    raise "Not going to create a bucket in this environment" unless
        %w(development test).include?(Rails.env)
    client   = Aws::S3::Client.new
    resource = Aws::S3::Resource.new
    bucket   = ::Configuration.instance.aws[:bucket]
    unless resource.bucket(bucket).exists?
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
  def self.new_in_staging(item, filename, length)
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
  def self.staging_key(item_id, filename)
    [STAGING_KEY_PREFIX, item_id, filename].join("/")
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
    s3_client.delete_object(bucket: ::Configuration.instance.aws[:bucket],
                            key:    self.staging_key)
  rescue Aws::S3::Errors::NotFound
    # That's OK
  ensure
    self.update!(exists_in_staging: false, staging_key: nil)
  end

  ##
  # This method is only used during migration out of IDEALS-DSpace. It can be
  # removed afterwards.
  #
  # @return [String] Path on the IDEALS-DSpace file system relative to the
  #                  asset store root.
  #
  def dspace_relative_path
    dspace_id.present? ? ["",
                          dspace_id[0..1],
                          dspace_id[2..3],
                          dspace_id[4..5],
                          dspace_id].join("/") : nil
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
  #         nil if does not exist in Medusa.
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
    s3_client.put_object(bucket: ::Configuration.instance.aws[:bucket],
                         key:    self.staging_key,
                         body:   io)
    self.update!(exists_in_staging: true)
  end

  private


  def s3_client
    @s3_client = Aws::S3::Client.new unless @s3_client
    @s3_client
  end

  def validate_staging_properties
    if exists_in_staging && staging_key.blank?
      errors.add(:base, "Instance is marked as existing in staging, but its "\
          "staging key is blank.")
    end
  end

end
