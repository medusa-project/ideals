module MessagesHelper

  def badge_for_message_operation(operation)
    if operation == Message::Operation::DELETE
      class_ = "badge-danger"
    else
      class_ = "badge-primary"
    end
    html = "<span class=\"badge #{class_}\">#{operation.upcase}</span>"
    raw(html)
  end

  def badge_for_message_status(status)
    status = "no response" if status.blank?
    if status == "ok"
      class_ = "badge-success"
    else
      class_ = "badge-danger"
    end
    html = "<span class=\"badge #{class_}\">#{status.upcase}</span>"
    raw(html)
  end

end