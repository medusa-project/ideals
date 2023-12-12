# frozen_string_literal: true

##
# The expense of the check used to determine whether a user is allowed to
# submit to a collection is high and scales with the number of collections that
# need to be checked. For an institution with thousands of collections, it may
# take many tens of seconds. This job performs the check in the background and
# caches the result in {User#cached_submittable_collections}.
#
class CacheSubmittableCollectionsJob < ApplicationJob

  QUEUE = ApplicationJob::Queue::PUBLIC

  queue_as QUEUE

  ##
  # @param args [Hash] Hash with `:user`, `:client_ip`, `:client_hostname`, and
  #                    `:task` keys.
  #
  def perform(**args)
    user            = args[:user]
    client_ip       = args[:client_ip]
    client_hostname = args[:client_hostname]
    self.task       = args[:task]

    self.task&.update!(name:          self.class.name,
                       user:          user,
                       institution:   user.institution,
                       indeterminate: false,
                       queue:         QUEUE,
                       job_id:        self.job_id,
                       started_at:    Time.now,
                       status_text:   "Caching submittable collections for user #{user.email}")
    user.update!(caching_submittable_collections_task_id: self.task&.id)

    User.transaction do
      user.cached_submittable_collections.delete_all
      user.effective_submittable_collections(client_ip:       client_ip,
                                             client_hostname: client_hostname,
                                             task:            self.task).each do |collection|
        unless user.cached_submittable_collections.map(&:collection_id).include?(collection.id)
          user.cached_submittable_collections.build(collection: collection)
        end
      end
      user.submittable_collections_cached_at = Time.now
      user.save!
    end
  ensure
    user.update!(caching_submittable_collections_task_id: nil)
  end

end
