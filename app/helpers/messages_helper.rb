# frozen_string_literal: true

module MessagesHelper

  def badge_for_message_operation(operation)
    if operation == Message::Operation::DELETE
      class_ = "text-bg-danger"
    else
      class_ = "text-bg-primary"
    end
    html = "<span class=\"badge #{class_}\">#{operation.upcase}</span>"
    raw(html)
  end

  def badge_for_message_status(status)
    status = "no response" if status.blank?
    if status == "ok"
      class_ = "text-bg-success"
    else
      class_ = "text-bg-danger"
    end
    html = "<span class=\"badge #{class_}\">#{status.upcase}</span>"
    raw(html)
  end

end