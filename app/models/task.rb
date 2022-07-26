##
# Encapsulates a long-running (usually asynchronous) task, for the purpose of
# providing status updates.
#
# Usage example:
# ```
# task = Task.create!(name:        "MyTask",
#                     status_text: "Doing something")
# begin
#   # do stuff...
#   task.progress(0.3)
#   # do some more stuff...
#   task.progress(0.95, status_text: "Wrapping up")
# rescue => e
#   task.fail(detail:    e.message,
#             backtrace: e.backtrace)
# else
#   task.succeed
# end
# ```
#
# N.B.: it's important to use the custom mutator methods (e.g. {progress}
# rather than {update}) in the context of a transaction. These will update the
# instance via a separate database connection--otherwise the update would not
# be visible from outside of the transaction.
#
# # Attributes
#
# * `backtrace`        Backtrace of a task that failed due to an exception.
# * `created_at`       Managed by ActiveRecord.
# * `detail`           Detailed results of the task.
# * `indeterminate`    If true, the task's progress cannot be computed and
#                      {percent_complete} is irrelevant.
# * `name`             Consistent name for the task, common across all tasks
#                      that do the same thing. The name of an [ApplicationJob]
#                      subclass would be an example of a good name.
# * `percent_complete` Float between 0 and 1. Irrelevant if the task is
#                      {indeterminate}.
# * `status`           One of the [Task::Status] constant values.
# * `status_text`      Short message summarizing the current state of the task.
# * `started_at`       Time the task started.
# * `stopped_at`       Time the task stopped (successfully or not).
# * `updated_at`       Managed by ActiveRecord.
# * `user_id`          Foreign key to the [User] who invoked the task.
#
class Task < ApplicationRecord

  class Status
    PENDING   = 0
    RUNNING   = 1
    PAUSED    = 2
    STOPPED   = 3
    SUCCEEDED = 4
    FAILED    = 5

    ##
    # @param status [Integer] One of the [Status] constant values.
    # @return [String] Human-readable status.
    #
    def self.to_s(status)
      case status
      when Status::PENDING
        'Pending'
      when Status::RUNNING
        'Running'
      when Status::PAUSED
        'Paused'
      when Status::STOPPED
        'Stopped'
      when Status::SUCCEEDED
        'Succeeded'
      when Status::FAILED
        'Failed'
      else
        self.to_s
      end
    end
  end

  has_one :download
  belongs_to :user, optional: true

  before_save :constrain_progress

  ##
  # @return [Time,nil]
  #
  def estimated_completion
    if self.percent_complete < 0.000001 || self.percent_complete > 0.999999 ||
        self.started_at.blank? || self.stopped_at.present?
      nil
    else
      TimeUtils.eta(self.started_at, self.percent_complete)
    end
  end

  ##
  # Fails the instance by setting its status to {Status::FAILED}.
  #
  def fail(detail: nil, backtrace: nil)
    self.class.connection_pool.with_connection do
      self.update!(status:     Status::FAILED,
                   stopped_at: Time.now,
                   detail:     detail,
                   backtrace:  backtrace)
    end
  end

  def failed?
    self.status == Status::FAILED
  end

  ##
  # Pauses the instance by setting its status to {Status::PAUSED}.
  #
  def pause
    self.class.connection_pool.with_connection do
      self.update!(status: Status::PAUSED)
    end
  end

  def paused?
    self.status == Status::PAUSED
  end

  ##
  # Updates the progress of the instance, as well as perhaps some other
  # properties for convenience.
  #
  # N.B.: it's important to use this rather than {update} in the context
  # of a transaction. This method will update the progress via a separate
  # database connection--otherwise the update would not be visible from outside
  # of the transaction.
  #
  # @param progress [Float]
  # @param status_text [String] Optional shortcut to updating this attribute
  #                             directly.
  #
  def progress(progress, status_text: nil)
    if progress >= 1
      self.succeed(status_text: status_text)
    else
      self.percent_complete = progress
      self.started_at       = Time.now if self.started_at.blank?
      self.status           = Status::RUNNING if progress < 1
      self.status_text      = status_text if status_text.present?
      self.class.connection_pool.with_connection { self.save! }
    end
  end

  def running?
    self.status == Status::RUNNING
  end

  ##
  # Stops the instance by setting its status to {Status::STOPPED}.
  #
  def stop
    self.class.connection_pool.with_connection do
      self.update!(status:     Status::STOPPED,
                   stopped_at: Time.now)
    end
  end

  ##
  # @return [Boolean] Whether the instance is stopped, successfully or not.
  #
  def stopped?
    self.status == Status::STOPPED || succeeded? || failed?
  end

  ##
  # Completes the instance by setting its status to {Status::SUCCEEDED}.
  #
  # @param status_text [String] Optional shortcut to updating this attribute
  #                             directly.
  #
  def succeed(status_text: nil)
    self.status           = Status::SUCCEEDED
    self.percent_complete = 1
    self.stopped_at       = Time.now
    self.backtrace        = nil
    self.status_text      = status_text if status_text.present?
    self.class.connection_pool.with_connection { self.save! }
  end

  def succeeded?
    self.status == Status::SUCCEEDED
  end


  private

  def constrain_progress
    if self.percent_complete < 0
      self.percent_complete = 0
    elsif self.percent_complete > 1
      self.percent_complete = 1
    end
  end

end
