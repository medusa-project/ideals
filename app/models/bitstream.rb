##
# Binary file/object associated with an {Item}. The "bitstream" terminology
# comes from DSpace, which is what IDEALS used to be built on.
#
# # Attributes
#
# * `created_at`:        Managed by ActiveRecord.
# * `exists_in_staging`: Whether a corresponding object exists in the staging
#                        "area" (key prefix) of the application S3 bucket.
# * `item_id`:           Foreign key to {Item}.
# * `length`:            Size in bytes.
# * `media_type`:        Media/MIME type.
# * `medusa_key`:        S3 object key in the Medusa bucket. Set only when the
#                        bitstream has been ingested into Medusa.
# * `medusa_uuid`:       UUID of the corresponding binary in the Medusa
#                        Collection Registry. Set only after the bitstream has
#                        been ingested.
# * `original_filename`: Filename of the bitstream as submitted by the user.
# * `staging_key`:       S3 object key in the application bucket. May be set
#                        even though the bitstream does not exist in staging--
#                        check `exists_in_staging` to be sure.
# * `updated_at`:        Managed by ActiveRecord.
#
class Bitstream < ApplicationRecord
  belongs_to :item

  validates_numericality_of :length, greater_than_or_equal_to: 0, allow_blank: true
  validates_format_of :media_type, with: /[\w+-]+\/[\w+-]+/, allow_blank: true
  validates_format_of :medusa_uuid,
                      with: /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/,
                      message: 'UUID is invalid',
                      allow_blank: true

  validate :validate_staging_properties

  before_destroy :delete_from_staging

  # This must be a location that Medusa is configured to monitor
  STAGING_KEY_PREFIX = "uploads"

  ##
  # Computes a destination Medusa key based on the given arguments.
  #
  # @param handle [String]
  # @param filename [String]
  # @return [String]
  # @raises ArgumentError if either argument is blank.
  #
  def self.medusa_key(handle, filename)
    raise ArgumentError, "Handle is blank" if handle.blank?
    raise ArgumentError, "Filename is blank" if filename.blank?
    [handle, filename].join("/")
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
  # Deletes the corresponding object from the application S3 bucket.
  #
  def delete_from_staging
    s3_client.delete_object(bucket: ::Configuration.instance.aws[:bucket],
                            key:    self.staging_key) if self.exists_in_staging
    self.update!(exists_in_staging: false)
  end

  ##
  # @raises [RuntimeException] if the instance does not have an ID or staging
  #         key, or already exists in Medusa.
  #
  def upload_to_medusa
    target_key = self.class.medusa_key(self.item.handle,
                                       self.original_filename)
    MedusaIngest.send_bitstream_to_medusa(self, target_key)
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
