# frozen_string_literal: true

class EmptyTrashJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Hash] Hash with `:institution`, `:user`, and `:task` keys.
  #
  def perform(**args)
    institution = args[:institution]
    user        = args[:user]
    self.task   = args[:task]
    raise ArgumentError, "No institution provided" unless institution

    self.task&.update!(name:          self.class.name,
                       user:          user,
                       institution:   institution,
                       indeterminate: false,
                       queue:         QUEUE,
                       job_id:        self.job_id,
                       started_at:    Time.now,
                       status:        Task::Status::RUNNING,
                       status_text:   "Emptying the trash")

    items = Item.
      where(institution: institution).
      where(stage: Item::Stages::BURIED)
    count = items.count
    Item.uncached do
      items.find_each.with_index do |item, index|
        item.destroy!
        self.task&.progress(index / count.to_f)
      end
    end
    OpenSearchClient.instance.refresh
  end

end
