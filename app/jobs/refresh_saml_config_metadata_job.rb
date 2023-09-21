# frozen_string_literal: true

class RefreshSamlConfigMetadataJob < ApplicationJob

  queue_as :admin

  ##
  # N.B.: in development & test, instead of fetching the real OAF metadata,
  # the `oaf_metadata.xml` file fixture is used.
  #
  # @param args [Array<Hash>] One-element array containing a Hash with
  #                           `:institution` and `:user` keys.
  #                           `:configuration_file` or `:configuration_url`
  #                           keys are optional for non-federated institutions.
  #
  def perform(*args)
    institution = args[0][:institution]
    user        = args[0][:user]
    config_file = args[0][:configuration_file]
    config_url  = args[0][:configuration_url]
    task        = Task.create!(name:          self.class.name,
                               indeterminate: true,
                               institution:   institution,
                               user:          user,
                               started_at:    Time.now,
                               status_text:   "Updating SAML configuration "\
                                              "metadata for #{institution.name}")
    is_temp_file = false
    begin
      if config_file.present?
        xml_file = config_file
      elsif config_url.present?
        xml_file = Institution.fetch_saml_config_metadata(url: config_url)
      elsif Rails.env.development? || Rails.env.test?
        xml_file = File.new(File.join(Rails.root, "test", "fixtures", "files",
                                      "oaf_metadata.xml"))
      else
        xml_file     = Institution.fetch_saml_config_metadata(federation: institution.sso_federation)
        is_temp_file = true
      end
      institution.update_from_saml_config_metadata(xml_file)
    rescue => e
      task.fail(detail:    e.message,
                backtrace: e.backtrace)
    else
      task.succeed
    ensure
      xml_file.unlink if is_temp_file
    end
  end

end
