module TasksHelper

  ##
  # @param status [Integer] One of the [Task::Status] constant values.
  # @return [String]
  #
  def bootstrap_class_for_task_status(status)
    case status
    when ::Task::Status::PENDING
      "badge-light"
    when ::Task::Status::PAUSED
      "badge-warning"
    when ::Task::Status::RUNNING
      "badge-primary"
    when ::Task::Status::STOPPED
      "badge-secondary"
    when ::Task::Status::SUCCEEDED
      "badge-success"
    when ::Task::Status::FAILED
      "badge-danger"
    end
  end

end