##
# Binary file/object associated with an {Item}. The "bitstream" terminology
# comes from DSpace, which is what IDEALS used to be built on.
#
# # Attributes
#
# * `created_at`:        Managed by ActiveRecord.
# * `item_id`:           Foreign key to {Item}.
# * `key`:               S3 object key.
# * `length`:            Size in bytes.
# * `media_type`:        Media/MIME type.
# * `medusa_uuid`:       UUID of the corresponding binary in the Medusa
#                        Collection Registry. Will be nil if the bitstream has
#                        not yet been ingested.
# * `original_filename`: Filename of the bitstream as submitted by the user.
# * `updated_at`:        Managed by ActiveRecord.
#
class Bitstream < ApplicationRecord
  belongs_to :item

  validates :key, presence: { allow_blank: false }, uniqueness: true
  validates_numericality_of :length, greater_than_or_equal_to: 0, allow_blank: true
  validates_format_of :media_type, with: /[\w+-]+\/[\w+-]+/, allow_blank: true
  validates_format_of :medusa_uuid,
                      with: /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/,
                      message: 'UUID is invalid',
                      allow_blank: true

  before_destroy :delete_object

  STAGING_KEY_PREFIX = "submissions"

  ##
  # @param item [Item]
  # @param filename [String]
  # @param length [Integer]
  # @return [Bitstream] New instance.
  #
  def self.new_in_staging(item, filename, length)
    Bitstream.new(item:              item,
                  key:               staging_key(item.id, filename),
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
  def delete_object
    s3_client.delete_object(bucket: ::Configuration.instance.aws[:bucket],
                            key:    self.key)
  end

  ##
  # @param io [IO]
  #
  def upload_to_staging(io)
    s3_client.put_object(bucket: ::Configuration.instance.aws[:bucket],
                         key:    self.key,
                         body:   io)
  end

  private

  def s3_client
    @s3_client = Aws::S3::Client.new unless @s3_client
    @s3_client
  end

end
