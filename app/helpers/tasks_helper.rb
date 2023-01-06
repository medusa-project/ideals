module TasksHelper

  ##
  # @param task [Task, Integer] Either a {Task} instance or one of the
  #                             {Task::Status} constant values.
  # @return [String] HTML string.
  #
  def task_status_badge(task)
    class_ = nil
    status = task.kind_of?(Integer) ? task : task.status
    case status
    when ::Task::Status::PENDING
      class_ = "bg-light"
    when ::Task::Status::PAUSED
      class_ = "bg-warning"
    when ::Task::Status::RUNNING
      class_ = "bg-primary"
    when ::Task::Status::STOPPED
      class_ = "bg-secondary"
    when ::Task::Status::SUCCEEDED
      class_ = "bg-success"
    when ::Task::Status::FAILED
      class_ = "bg-danger"
    end
    raw("<span class=\"badge #{class_}\">#{Task::Status::to_s(status)}</span>")
  end

end