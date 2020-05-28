##
# Binary file/object associated with an {Item}. The "bitstream" terminology
# comes from DSpace, which is what IDEALS used to be built on.
#
# # Attributes
#
# * `created_at`:        Managed by ActiveRecord.
# * `item_id`:           Foreign key to {Item}.
# * `length`:            Size in bytes.
# * `media_type`:        Media/MIME type.
# * `medusa_key`:        S3 object key in the Medusa bucket. Set only when the
#                        bitstream has been ingested into Medusa.
# * `medusa_uuid`:       UUID of the corresponding binary in the Medusa
#                        Collection Registry. Set only after the bitstream has
#                        been ingested.
# * `original_filename`: Filename of the bitstream as submitted by the user.
# * `staging_key`:       S3 object key in the application bucket. Set only when
#                        the bitstream exists in staging.
# * `updated_at`:        Managed by ActiveRecord.
#
class Bitstream < ApplicationRecord
  belongs_to :item

  validates :medusa_key, presence: { allow_blank: true }, uniqueness: true
  validates :staging_key, presence: { allow_blank: true }, uniqueness: true
  validates_numericality_of :length, greater_than_or_equal_to: 0, allow_blank: true
  validates_format_of :media_type, with: /[\w+-]+\/[\w+-]+/, allow_blank: true
  validates_format_of :medusa_uuid,
                      with: /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/,
                      message: 'UUID is invalid',
                      allow_blank: true

  before_destroy :delete_from_staging

  STAGING_KEY_PREFIX = "submissions"

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
    config = ::Configuration.instance
    [config.medusa[:medusa_path_root], handle, filename].join("/")
  end

  ##
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
  end

  ##
  # @param io [IO]
  #
  def upload_to_staging(io)
    s3_client.put_object(bucket: ::Configuration.instance.aws[:bucket],
                         key:    self.staging_key,
                         body:   io)
  end

  private

  def s3_client
    @s3_client = Aws::S3::Client.new unless @s3_client
    @s3_client
  end

end
