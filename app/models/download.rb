# frozen_string_literal: true

##
# Represents a file download.
#
# This model is part of a system that can be used for downloads that may take
# a non-trivial amount of time to prepare. A typical workflow is:
#
# 1. The user clicks a download button.
# 2. The responding controller creates a [Download] instance, invokes an
#    asynchronous job to prepare the file for download, and redirects to the
#    instance's URL.
# 3. The job associates the Download with a [Task], which enables progress
#    reporting.
# 4. The job does its work, periodically updating the {Task#percent_complete}
#    attribute to keep the user informed. When done, it sets {filename} to the
#    file's filename, and sets {Task#status} to {Task::Status::SUCCEEDED}.
# 5. The page reloads automatically via XHR, and now contains a link which the
#    user follows to download the file.
#
# Periodically, old [Download] records and their corresponding files should be
# cleaned up using the `downloads:cleanup` rake task. This will mark them as
# expired and delete their corresponding files. Expired instances are kept
# around for record keeping.
#
# # Storage
#
# Downloads are stored in the application S3 bucket under the
# `institutions/:key/downloads/` key prefix.
#
# # Attributes
#
# * `created_at`     Managed by ActiveRecord.
# * `expired`        When a download is expired, it is no longer usable and its
#                    associated file is no longer available. Client code should
#                    call {expire} rather than setting this directly.
# * `filename`       Filename of the file to be downloaded. ({url} can be used
#                    instead.
# * `key`            Random alphanumeric "public ID." Should be hard to guess
#                    so that someone can't access someone else's download.
# * `institution_id` Foreign key to [Institution].
# * `task_id`        Foreign key to [Task].
# * `updated_at`     Managed by ActiveRecord.
# * `url`            URL to redirect to rather than downloading a local file.
#                    Must be publicly accessible.
#
class Download < ApplicationRecord

  LOGGER = CustomLogger.new(Download)

  belongs_to :institution
  belongs_to :task, optional: true

  before_create :assign_key
  after_destroy :delete_object

  ##
  # @param max_age_seconds [Integer]
  # @return [void]
  #
  def self.cleanup(max_age_seconds)
    max_age_seconds = max_age_seconds.to_i
    num_expired     = 0
    # Expire instances more than max_age_seconds old.
    Download.uncached do
      Download.
          where(expired: false).
          where("updated_at < ?", Time.at(Time.now.to_i - max_age_seconds)).
          find_each do |download|
        download.expire
        num_expired += 1
      end
    end
    LOGGER.info("cleanup(): expired %d instances > %d seconds old.",
                num_expired, max_age_seconds)
  end

  ##
  # Sets the instance's {expired} attribute to true and deletes its
  # corresponding file.
  #
  # @return [void]
  #
  def expire
    delete_object
    self.update!(expired: true)
  end

  ##
  # @return [String, nil]
  #
  def object_key
    return nil unless self.institution
    return nil if self.filename.blank?
    [
      Bitstream::INSTITUTION_KEY_PREFIX,
      self.institution.key,
      "downloads",
      self.filename
    ].join("/")
  end

  ##
  # @param expiry_seconds [Integer]
  # @return [String]
  #
  def presigned_url(expiry_seconds: 900)
    ObjectStore.instance.presigned_download_url(
      key:                          self.object_key,
      expires_in:                   expiry_seconds,
      response_content_disposition: content_disposition(self.filename))
  end

  ##
  # @return [Boolean]
  #
  def ready?
    (self.filename || self.url) && self.task&.succeeded?
  end

  ##
  # @return [String] The key.
  #
  def to_param
    self.key
  end


  private

  def assign_key
    self.key = SecureRandom.hex
  end

  def content_disposition(filename)
    utf8_filename  = filename
    ascii_filename = utf8_filename.gsub(/[^[:ascii:]]*/, '')
    # N.B.: CGI.escape() inserts "+" instead of "%20" which Chrome interprets
    # literally, so we use ERB::Util.url_encode() instead.
    "attachment; filename=\"#{ascii_filename.gsub('"', "\"")}\"; "\
        "filename*=UTF-8''#{ERB::Util.url_encode(utf8_filename)}"
  end

  def delete_object
    if self.filename.present?
      key = self.object_key
      LOGGER.debug('delete_object(): deleting %s', key)
      ObjectStore.instance.delete_object(key: key)
    end
  end

end
