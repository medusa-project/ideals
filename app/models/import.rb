# frozen_string_literal: true

##
# Represents a batch import of {Item}s, such as via {CsvImporter} or
# {SafImporter}.
#
# See the documentation of {ImportsController} for an explanation of how
# importing works.
#
# # Attributes
#
# * `collection_id`  ID of the {Collection} into which new items are to be
#                    imported.
# * `created_at`     Managed by ActiveRecord.
# * `files`          JSON array of all files to import.
# * `format`         One of the {Import::Format} constant values. This may be
#                    null in the case of a newly created instance to which
#                    files have not been uploaded yet.
# * `imported_items` JSON array of objects with `item_id` and `handle` keys.
#                    This is analogous to the contents of a mapfile (see
#                    {SafImporter}) and can be used to reconstruct one.
# * `institution_id` Foreign key to {Institution} representing the institution
#                    into which items are being imported.
# * `task_id`        Foreign key to {Task} which can be used for status
#                    reports.
# * `updated_at`     Managed by ActiveRecord.
# * `user_id`        ID of the {User} who initiated the import.
#
class Import < ApplicationRecord

  class Format
    SAF         = 0
    CSV_FILE    = 1
    CSV_PACKAGE = 2

    def self.to_s(format)
      case format
      when 0
        "SAF Package"
      when 1
        "CSV File"
      when 2
        "CSV Package"
      else
        "Unknown"
      end
    end
  end

  belongs_to :collection
  belongs_to :institution
  belongs_to :task, optional: true
  belongs_to :user

  serialize :files, JSON
  serialize :imported_items, JSON

  before_save :delete_all_files_upon_success
  before_destroy :delete_all_files

  def delete_all_files
    PersistentStore.instance.delete_objects(key_prefix: self.root_key_prefix)
  end

  ##
  # @return [Enumerable<String>] Key prefix of every item in the package.
  #
  def item_key_prefixes
    object_keys.map{ |k| k.split("/")[0..-2].join("/") }.uniq
  end

  ##
  # Returns an object key within the application bucket for the file with the
  # given name. This file is used by the {SafImporter} and should be deleted
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
    PersistentStore.instance.objects(key_prefix: root_key_prefix).map(&:key)
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
      self.task&.progress(progress)
      self.update!(imported_items: imported_items)
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
     self.id].join("/") + "/"
  end

  ##
  # @param relative_path [String] Path of a file within an import package
  #                               relative to the root of the package.
  # @param io [IO]
  #
  def upload_file(relative_path:, io:)
    Tempfile.open("import") do |tempfile|
      IO.copy_stream(io, tempfile)
      tempfile.close
      store = PersistentStore.instance
      key   = object_key(relative_path)
      # When used to simply upload the IO argument, put_object() fails randomly
      # and silently as of AWS SDK 1.111.0/Rails 7. Here is a workaround
      # whereby we retry the upload as many times as necessary, pausing in
      # between attempts. Don't ask me why the pausing works. (Is this only a
      # problem with Minio?)
      20.times do
        store.put_object(key:             key,
                         institution_key: self.institution.key,
                         path:            tempfile.path)
        sleep 1
        break if store.object_exists?(key: key)
      end
    end
  end


  private

  def delete_all_files_upon_success
    self.delete_all_files if self.task&.succeeded?
  end

  def validate_imported_items
    begin
      JSON.parse(imported_items)
    rescue
      errors.add(:imported_items, "must be valid JSON")
    end
  end

end
