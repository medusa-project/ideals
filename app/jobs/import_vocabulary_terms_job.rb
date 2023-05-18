class ImportVocabularyTermsJob < ApplicationJob

  queue_as :public

  ##
  # @param args [Array<Hash>] One-element array containing a hash with
  #                           `vocabulary`, `pathname`, and `user` keys.
  #
  def perform(*args)
    vocabulary = args[0][:vocabulary]
    pathname   = args[0][:pathname]
    user       = args[0][:user]
    task       = Task.create!(name:          self.class.name,
                              indeterminate: false,
                              institution:   vocabulary.institution,
                              user:          user,
                              started_at:    Time.now,
                              status_text:   "Importing vocabulary terms "\
                                             "into #{vocabulary.name}")
    begin
      vocabulary.import_terms_from_csv(pathname: pathname, task: task)
    rescue => e
      task.fail(detail:    e.message,
                backtrace: e.backtrace)
    else
      task.succeed
    ensure
      File.unlink(pathname)
    end
  end

end
