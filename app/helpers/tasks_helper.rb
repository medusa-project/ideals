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
      class_ = "badge-light"
    when ::Task::Status::PAUSED
      class_ = "badge-warning"
    when ::Task::Status::RUNNING
      class_ = "badge-primary"
    when ::Task::Status::STOPPED
      class_ = "badge-secondary"
    when ::Task::Status::SUCCEEDED
      class_ = "badge-success"
    when ::Task::Status::FAILED
      class_ = "badge-danger"
    end
    raw("<span class=\"badge #{class_}\">#{Task::Status::to_s(task.status)}</span>")
  end

end