##
# Represents an import of a batch of [Item]s, such as via [SafImporter].
#
# # Attributes
#
# * `collection_id`      ID of the [Collection] into which items are to be
#                        imported.
# * `created_at`         Managed by ActiveRecord.
# * `files`              JSON array of all files to import.
# * `imported_items`     JSON array of objects with `item_id` and `handle` keys.
#                        This is analogous to the contents of a mapfile (see
#                        [SafImporter]) and can be used to reconstruct one.
# * `last_error_message` Last error message emitted by the importer.
# * `percent_complete`   Float in the range 0-1.
#                        TODO: updates within a transaction aren't visible outside of the transaction, so move this into a generic "Task" class which uses a separate database connection.
# * `status`             One of the [Import::Status] constant values.
# * `updated_at`         Managed by ActiveRecord.
# * `user_id`            ID of the [User] who initiated the import.
#
class Import < ApplicationRecord

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
  belongs_to :user

  serialize :files, JSON
  serialize :imported_items, JSON

  before_save :update_percent_complete_upon_success,
              :delete_all_files_upon_success
  before_destroy :delete_all_files

  validates :status, inclusion: { in: Status.all }

  def delete_all_files
    config = ::Configuration.instance
    S3Client.instance.delete_objects(bucket:     config.aws[:bucket],
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
    S3Client.instance.objects(bucket:     ::Configuration.instance.aws[:bucket],
                              key_prefix: root_key_prefix).map(&:key)
  end

  ##
  # @return [String] Root key prefix of the package.
  #
  def root_key_prefix
    raise "Instance is not persisted" if self.id.blank?
    "imports/#{self.id}/"
  end

  ##
  # @param relative_path [String]
  # @param io [IO]
  #
  def upload_file(relative_path:, io:)
    S3Client.instance.put_object(bucket: ::Configuration.instance.aws[:bucket],
                                 key:    object_key(relative_path),
                                 body:   io)
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
