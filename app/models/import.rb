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
# * `filename`       Name of the file to import.
# * `format`         One of the {Import::Format} constant values. This may be
#                    null in the case of a newly created instance to which
#                    files have not been uploaded yet.
# * `imported_items` JSON array of objects with `item_id` and `handle` keys.
#                    This is analogous to the contents of a mapfile (see
#                    {SafImporter}) and can be used to reconstruct one.
# * `institution_id` Foreign key to {Institution} representing the institution
#                    into which items are being imported.
# * `length`         Length of the file identified by {filename}.
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
  belongs_to :user, optional: true

  serialize :imported_items, JSON

  before_save :delete_all_files_upon_success
  before_destroy :delete_all_files

  def delete_all_files
    fs_root = self.filesystem_root
    FileUtils.rm_r(fs_root) if File.exist?(fs_root)
  end

  ##
  # @return [String] File pathname.
  #
  def file
    return nil if self.filename.blank?
    File.join(self.filesystem_root, self.filename)
  end

  ##
  # @return [String]
  #
  def filesystem_root
    raise "Instance not persisted" if self.id.blank?
    tmpdir = Dir.tmpdir
    File.join(tmpdir, "ideals_imports", self.institution.key, self.id.to_s)
  end

  ##
  # @param progress [Float]
  # @param imported_items [Array<Hash>] Array of hashes with `:item_id` and
  #                                     `:handle` keys.
  #
  def progress(progress, imported_items = [])
    self.task&.progress(progress)
    self.update!(imported_items: imported_items)
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
  # Saves an uploaded file to a temporary location.
  #
  # @param file [File]
  # @param filename [String]
  #
  def save_file(file:, filename:)
    self.update!(filename: filename, length: File.size(file))
    import_root = filesystem_root
    FileUtils.mkdir_p(import_root)
    path = File.join(import_root, filename)
    FileUtils.cp(file.path, path)
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
