# frozen_string_literal: true

class RefreshOpenathensMetadataJob < ApplicationJob

  queue_as :admin

  ##
  # N.B.: in development & test, instead of fetching the real OAF metadata,
  # the `oaf_metadata.xml` file fixture is used.
  #
  # @param args [Array<Hash>] One-element array containing a Hash with
  #                           `:institution` and `:user` keys.
  #
  def perform(*args)
    institution = args[0][:institution]
    user        = args[0][:user]
    task        = Task.create!(name:          self.class.name,
                               indeterminate: true,
                               institution:   institution,
                               user:          user,
                               started_at:    Time.now,
                               status_text:   "Updating OpenAthens Federation "\
                                              "metadata for #{institution.name}")
    is_temp_file = false
    begin
      if Rails.env.development? || Rails.env.test?
        xml_file = File.new(File.join(Rails.root, "test", "fixtures", "files",
                                      "oaf_metadata.xml"))
      else
        xml_file     = Institution.fetch_openathens_metadata
        is_temp_file = true
      end
      institution.update_from_openathens(xml_file)
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
