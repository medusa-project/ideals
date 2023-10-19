# frozen_string_literal: true

##
# Superclass for all jobs with a main purpose of managing an associated {Task}.
#
# # Implementation notes
#
# 1. Implementations must define a `QUEUE` constant with a value of one of the
#    {ApplicationJob::Queue} constant values.
# 2. Implementations' {perform} method must accept a hash argument.
# 3. In their {perform} method, they should access the task noting that it may
#    be nil. Most necessary properties should get set automatically, but the
#    {Task#status_text} property will need updating. It may also want to update
#    other properties like {Task#indeterminate} or any other property that
#    hasn't been set the way it should by {create_task}.
#
# Implementations should not rescue errors, and should rethrow them if they do.
#
# N.B. when running jobs synchronously, it is important to call
# `MyJob.perform_now` and not `MyJob.new.perform`. The latter will not employ
# any of the mechanics implemented by this class.
#
class ApplicationJob < ActiveJob::Base

  class Queue
    ADMIN  = :admin
    PUBLIC = :public

    def self.all
      self.constants.map{ |c| self.const_get(c) }
    end
  end

  attr_writer :task

  before_enqueue :do_before_enqueue
  after_enqueue :do_after_enqueue
  before_perform :do_before_perform
  after_perform :do_after_perform

  rescue_from(Exception) do |e|
    fail_task(e)
    if Rails.env.demo? || Rails.env.production?
      message = IdealsMailer.error_body(e)
      IdealsMailer.error(message).deliver_now
    end
    raise e
  end

  ##
  # Override if no {Task} should be created.
  #
  # @return [Boolean]
  #
  def has_task?
    true
  end

  ##
  # @return [Task,nil] Task associated with the job.
  #
  def task
    if has_task? && !@task && self.job_id
      @task = Task.find_by_job_id(self.job_id)
    end
    @task
  end


  protected

  ##
  # N.B. this only gets called when {perform_later} is used.
  #
  def do_before_enqueue
  end

  ##
  # N.B. this only gets called when {perform_later} is used.
  #
  def do_after_enqueue
    create_task if has_task?
  end

  def do_before_perform
    create_task if has_task?
    self.task&.update!(status:     Task::Status::RUNNING,
                       started_at: Time.now)
  end

  def do_after_perform
    self.task&.succeed
  end


  private

  def create_task
    unless Task.find_by_job_id(self.job_id)
      Task.create!(name:        self.class.name,
                   user:        arguments[0].dig(:user),
                   institution: arguments[0].dig(:institution),
                   status_text: "Waiting...",
                   job_id:      self.job_id,
                   queue:       self.class::QUEUE)
    end
  end

  ##
  # @param e [Exception]
  #
  def fail_task(e)
    self.task&.update!(status:     Task::Status::FAILED,
                       stopped_at: Time.now,
                       detail:     "#{e}",
                       backtrace:  e.backtrace)
  end

end
