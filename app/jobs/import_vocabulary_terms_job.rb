# frozen_string_literal: true

class ImportVocabularyTermsJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Hash] Hash with `:vocabulary`, `:pathname`, `:user`, and
  #                    `:task` keys.
  #
  def perform(**args)
    vocabulary = args[:vocabulary]
    pathname   = args[:pathname]
    user       = args[:user]
    self.task  = args[:task]
    self.task&.update!(name:          self.class.name,
                       user:          user,
                       institution:   vocabulary.institution,
                       indeterminate: false,
                       queue:         QUEUE,
                       job_id:        self.job_id,
                       started_at:    Time.now,
                       status_text:   "Importing vocabulary terms into "\
                                      "#{vocabulary.name}")
    begin
      vocabulary.import_terms_from_csv(pathname: pathname, task: task)
    ensure
      File.unlink(pathname)
    end
  end

end
