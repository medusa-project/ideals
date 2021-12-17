module ImportsHelper

  ##
  # @param import [Import]
  # @return [String]
  #
  def import_status(import)
    case import.status
    when Import::Status::RUNNING
      text        = "Running"
      badge_class = "badge-primary"
    when Import::Status::SUCCEEDED
      text        = "Succeeded"
      badge_class = "badge-success"
    when Import::Status::FAILED
      text        = "Failed"
      badge_class = "badge-danger"
    else
      text        = "Waiting For Files"
      badge_class = "badge-secondary"
    end
    raw("<span class=\"badge #{badge_class}\">#{text}</span>")
  end

end