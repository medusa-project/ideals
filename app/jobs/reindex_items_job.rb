class ReindexItemsJob < ApplicationJob

  LOGGER = CustomLogger.new(ReindexItemsJob)

  queue_as :admin

  ##
  # @param args [Array] One-element array with an Enumerable of Collections at
  #                     position 0.
  #
  def perform(*args)
    collections = args[0]
    profile     = collections.first.effective_metadata_profile
    task        = Task.create!(name:        self.class.name,
                               status_text: "Reindexing items in "\
                                            "#{collections.length} collections "\
                                            "associated with the "\
                                            "#{profile.name} metadata profile")
    begin
      item_count = collections.map{ |c| c.items.count }.sum
      task.update!(status_text: "Reindexing #{item_count} items associated "\
                                "with the #{profile.name} metadata.profile")
      index = 0
      collections.each do |col|
        col.items.each do |item|
          item.reindex
          index += 1
          task.progress(index / item_count.to_f) if index % 10 == 0
        end
      end
    rescue => e
      task.fail(detail:    e.message,
                backtrace: e.backtrace)
    else
      task.succeed
    end
  end

end
