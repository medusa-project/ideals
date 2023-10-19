class ImportVocabularyTermsJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Hash] Hash with `vocabulary`, `pathname`, and `user` keys.
  #
  def perform(**args)
    vocabulary = args[:vocabulary]
    pathname   = args[:pathname]
    task       = self.task&.update!(institution: vocabulary.institution,
                                    status_text: "Importing vocabulary terms "\
                                                 "into #{vocabulary.name}")
    begin
      vocabulary.import_terms_from_csv(pathname: pathname, task: task)
    ensure
      File.unlink(pathname)
    end
  end

end
