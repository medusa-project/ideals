##
# Represents a batch import of [Item]s, such as via [CsvImporter] or
# [SafImporter].
#
# # Attributes
#
# * `collection_id`      ID of the [Collection] into which new items are to be
#                        imported.
# * `created_at`         Managed by ActiveRecord.
# * `files`              JSON array of all files to import.
# * `imported_items`     JSON array of objects with `item_id` and `handle` keys.
#                        This is analogous to the contents of a mapfile (see
#                        [SafImporter]) and can be used to reconstruct one.
# * `institution_id`     Foreign key to [Institution] representing the
#                        institution into which items are being imported.
# * `kind`               One of the [Import::Kind] constant values. This may be
#                        null in the case of a newly created instance to which
#                        files have not been uploaded yet.
# * `last_error_message` Last error message emitted by the importer.
# * `percent_complete`   Float in the range 0-1.
# * `status`             One of the [Import::Status] constant values.
# * `updated_at`         Managed by ActiveRecord.
# * `user_id`            ID of the [User] who initiated the import.
#
class Import < ApplicationRecord

  class Kind
    SAF = 0
    CSV = 1

    def self.to_s(kind)
      case kind
      when 0
        "SAF Package"
      when 1
        "CSV File"
      else
        "Unknown"
      end
    end
  end

  class Status
    NEW       = 0
    RUNNING   = 1
    SUCCEEDED = 2
    FAILED    = 3

    def self.all
      self.constants.map{ |c| self.const_get(c) }
    end
  end

  belongs_to :collection
  belongs_to :institution
  belongs_to :user

  serialize :files, JSON
  serialize :imported_items, JSON

  before_save :update_percent_complete_upon_success,
              :delete_all_files_upon_success
  before_destroy :delete_all_files

  validates :status, inclusion: { in: Status.all }

  def delete_all_files
    config = ::Configuration.instance
    S3Client.instance.delete_objects(bucket:     config.storage[:bucket],
                                     key_prefix: self.root_key_prefix)
  end

  ##
  # @return [Enumerable<String>] Key prefix of every item in the package.
  #
  def item_key_prefixes
    object_keys.map{ |k| k.split("/")[0..-2].join("/") }.uniq
  end

  ##
  # Returns an object key within the application bucket for the file with the
  # given name. This file is used by the [SafImporter] and should be deleted
  # following the import.
  #
  # @param relative_path [String] Pathname of a file contained within an SAF
  #                               package relative to the package root.
  # @return [String] Name of the object key for the given file within the
  #                  application S3 bucket.
  #
  def object_key(relative_path)
    root_key_prefix + relative_path.reverse.chomp("/").reverse
  end

  ##
  # @return [Enumerable<String>] All object keys in the package.
  #
  def object_keys
    config = ::Configuration.instance
    S3Client.instance.objects(bucket:     config.storage[:bucket],
                              key_prefix: root_key_prefix).map(&:key)
  end

  ##
  # Updates the progress using a separate database connection, making it usable
  # from inside a transaction block.
  #
  # @param progress [Float]
  # @param imported_items [Array<Hash>] Array of hashes with `:item_id` and
  #                                     `:handle` keys.
  #
  def progress(progress, imported_items = [])
    self.class.connection_pool.with_connection do
      self.update!(percent_complete: progress,
                   imported_items:   imported_items)
    end
  end

  ##
  # @return [String] Root key prefix of the package.
  #
  def root_key_prefix
    raise "Instance is not persisted" if self.id.blank?
    [Bitstream::INSTITUTION_KEY_PREFIX,
     self.institution.key,
     "imports",
     self.id].join("/")
  end

  ##
  # @param relative_path [String]
  # @param io [IO]
  #
  def upload_file(relative_path:, io:)
    Tempfile.open("import") do |tempfile|
      IO.copy_stream(io, tempfile)
      tempfile.close
      client = S3Client.instance
      bucket = ::Configuration.instance.storage[:bucket]
      key    = object_key(relative_path)
      # When used to simply upload the IO argument, put_object() fails randomly
      # and silently as of AWS SDK 1.111.0/Rails 7. Here is a workaround
      # whereby we retry the upload as many times as necessary, pausing in
      # between attempts. Don't ask me why the pausing works. (Is this only a
      # problem with Minio?)
      20.times do
        client.put_object(bucket: bucket,
                          key:    key,
                          body:   tempfile)
        sleep 1
        break if client.object_exists?(bucket: bucket, key: key)
      end
    end
  end


  private

  def delete_all_files_upon_success
    self.delete_all_files if status == Status::SUCCEEDED
  end

  def update_percent_complete_upon_success
    self.percent_complete = 1 if status == Status::SUCCEEDED
  end

  def validate_imported_items
    begin
      JSON.parse(imported_items)
    rescue
      errors.add(:imported_items, "must be valid JSON")
    end
  end

end
