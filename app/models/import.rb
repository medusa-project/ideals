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
  belongs_to :task, optional: true # an importer will assign this
  belongs_to :user, optional: true

  serialize :imported_items, JSON

  before_save :delete_file, if: -> { task&.succeeded? }
  before_destroy :delete_file

  def delete_file
    if self.id.present? && self.institution_id.present? &&
      self.filename.present?
      File.delete(self.file) if File.exist?(self.file)
      PersistentStore.instance.delete_object(key: self.file_key)
    end
  end

  ##
  # @return [String] File pathname.
  #
  def file
    raise "Instance is not persisted" if self.id.blank?
    raise "Instance is not associated with an institution" unless self.institution_id
    raise "Filename is not set" if self.filename.blank?
    File.join(Dir.tmpdir, "ideals_imports", self.institution.key, self.id.to_s,
              self.filename)
  end

  ##
  # @return [String] Key of the file to import within the application S3
  #                  bucket.
  #
  def file_key
    raise "Instance is not persisted" if self.id.blank?
    raise "Instance is not associated with an institution" unless self.institution_id
    raise "Filename is not set" if self.filename.blank?
    [Bitstream::INSTITUTION_KEY_PREFIX,
     self.institution.key,
     "imports",
     self.id,
     self.filename].join("/")
  end

  ##
  # @return [Array<Hash>]
  #
  def presigned_upload_url
    PersistentStore.instance.presigned_upload_url(key:        self.file_key,
                                                  expires_in: 60 * 60)
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


  private

  def validate_imported_items
    begin
      JSON.parse(imported_items)
    rescue
      errors.add(:imported_items, "must be valid JSON")
    end
  end

end
