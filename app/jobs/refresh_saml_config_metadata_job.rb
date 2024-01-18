# frozen_string_literal: true

class RefreshSamlConfigMetadataJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # N.B.: in development & test, instead of fetching the real OAF metadata,
  # the `oaf_metadata.xml` file fixture is used.
  #
  # @param args [Hash] Hash with `:institution`, `:user`, and `:task` keys.
  #                    `:configuration_file` or `:configuration_url` keys are
  #                    optional for non-federated institutions.
  #
  def perform(**args)
    institution = args[:institution]
    config_file = args[:configuration_file]
    config_url  = args[:configuration_url]
    user        = args[:user]
    self.task   = args[:task]
    self.task&.update!(name:          self.class.name,
                       user:          user,
                       institution:   institution,
                       indeterminate: true,
                       queue:         QUEUE,
                       job_id:        self.job_id,
                       started_at:    Time.now,
                       status:        Task::Status::RUNNING,
                       status_text:   "Updating SAML configuration "\
                                      "metadata for #{institution.name}")
    is_temp_file = false
    begin
      if config_file.present?
        xml_file = config_file
      elsif config_url.present?
        institution.update!(saml_metadata_url: config_url)
        xml_file = Institution.fetch_saml_config_metadata(url: config_url)
      elsif Rails.env.development? || Rails.env.test?
        xml_file = File.new(File.join(Rails.root, "test", "fixtures", "files",
                                      "oaf_metadata.xml"))
      else
        xml_file     = Institution.fetch_saml_config_metadata(federation: institution.sso_federation)
        is_temp_file = true
      end
      institution.update_from_saml_metadata(xml_file)
    ensure
      xml_file.unlink if is_temp_file && xml_file.respond_to?(:unlink)
    end
  end

end
