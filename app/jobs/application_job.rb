# frozen_string_literal: true

##
# Superclass for all jobs with a main purpose of managing an associated {Task}.
#
# # Implementation notes
#
# 1. Implementations must define a `QUEUE` constant with a value of one of the
#    {ApplicationJob::Queue} constant values.
# 2. Implementations' {perform} method must accept a hash argument.
# 3. In their {perform} method, they should update the properties of the {Task}
#    that is passed into them. They shouldn't create their own {Task} because
#    it could lead to multiple tasks being created for the same job.
#
# Implementations should not rescue errors, and should rethrow them if they do.
#
# N.B. when running jobs synchronously, it is important to call
# `MyJob.perform_now` and not `MyJob.new.perform`. The latter will not employ
# any of the mechanics implemented by this class.
#
class ApplicationJob < ActiveJob::Base

  class Queue
    ADMIN             = :admin
    PUBLIC            = :public
    PUBLIC_SEQUENTIAL = :public_sequential

    def self.all
      self.constants.map{ |c| self.const_get(c) }
    end

    def self.to_s(queue)
      case queue
      when Queue::ADMIN
        "Admin"
      when Queue::PUBLIC
        "Public"
      when Queue::PUBLIC_SEQUENTIAL
        "Public Sequential"
      else
        self.to_s
      end
    end
  end

  attr_writer :task

  # we are configuring this in config/initializers/delayed_job.rb instead
  #retry_on Exception, wait: :exponentially_longer, attempts: 1

  before_enqueue :do_before_enqueue
  after_enqueue :do_after_enqueue
  before_perform :do_before_perform
  after_perform :do_after_perform

  rescue_from(Exception) do |e|
    fail_task(e)
    if Rails.env.demo? || Rails.env.production?
      message = IdealsMailer.error_body(e) # TODO: include some other arguments, user at least
      IdealsMailer.error(message).deliver_now
    end
    raise e
  end

  ##
  # @return [Task,nil] Task associated with the job.
  #
  def task
    if !@task && self.job_id
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
  end

  def do_before_perform
    self.task&.update!(status:     Task::Status::RUNNING,
                       started_at: Time.now)
  end

  def do_after_perform
    self.task&.succeed
  end


  private

  ##
  # @param e [Exception]
  #
  def fail_task(e)
    self.task&.update!(status:     Task::Status::FAILED,
                       stopped_at: Time.now,
                       detail:     "#{e}",
                       backtrace:  self.task&.backtrace || e.backtrace)
  end

end
