module AuditableHelper

  ##
  # @param events [Enumerable<Event>]
  # @return [String] Bootstrap accordion element.
  #
  def events(events)
    return "" if events.empty?
    html = StringIO.new
    html << '<div id="events-accordion" class="accordion">'
    events.each do |event|
      html << '<div class="accordion-item">'
      html <<   "<h5 id=\"event-header-#{event.id}\" class=\"accordion-header\">"
      html <<     "<button class=\"accordion-button collapsed\" "\
                    "type=\"button\" "\
                    "data-bs-toggle=\"collapse\" "\
                    "data-bs-target=\"#event-#{event.id}\" "\
                    "aria-expanded=\"false\" "\
                    "aria-controls=\"event-#{event.id}\">"
      case event.event_type
      when Event::Type::CREATE, Event::Type::UNDELETE
        badge_class = "bg-success"
      when Event::Type::UPDATE
        badge_class = "bg-warning"
      when Event::Type::DELETE
        badge_class = "bg-danger"
      else
        badge_class = "bg-primary"
      end
      html <<       "<span class=\"badge #{badge_class} me-2\">"
      html <<         Event::Type.label(event.event_type).upcase
      html <<       '</span>'
      html <<       local_time(event.happened_at)
      if event.user
        html <<       link_to(event.user.becomes(User), class: "ms-2") do
          raw("#{icon_for(event.user)} <small>#{event.user.name}</small>")
        end
      end
      html <<     '</button>'
      html <<   '</h5>'
      html <<   "<div id=\"event-#{event.id}\" "\
                  "class=\"accordion-collapse collapse\" "\
                  "aria-labelledby=\"event-header-#{event.id}\" "\
                  "data-bs-parent=\"#events-accordion\">"
      html <<     '<div class="accordion-body">'
      html <<       '<p>'
      html <<         event.description
      html <<       '</p>'
      html <<       diff(event.before_changes, event.after_changes)
      html <<     '</div>'
      html <<   '</div>'
      html << '</div>'
    end
    html << '</div>'
    raw(html.string)
  end

  private

  ##
  # @param model1 [Hash] Hash of key-value pairs.
  # @param model2 [Hash] Hash of key-value pairs.
  # @return [String] HTML string.
  #
  def diff(model1, model2)
    return "" unless model1 || model2
    data = ModelUtils.diff(model1, model2)
    return "" if data.empty?
    html = StringIO.new
    html << '<table class="table table-sm">'
    data.each do |row|
      case row[:op]
      when :added
        class_ = "diff-added"
      when :removed
        class_ = "diff-removed"
      when :changed
        class_ = "diff-changed"
      else
        class_ = ''
      end
      html << '<tr>'
      html <<   "<td class=\"#{class_}\">"
      html <<     '<code>'
      html <<       row[:name]
      html <<     '</code>'
      html <<   '</td>'
      html <<   "<td class=\"#{class_}\">"
      html <<     '<code>'
      html <<       sanitize(row[:before_value].to_s)
      html <<     '</code>'
      html <<   '</td>'
      html <<   "<td class=\"#{class_}\" style=\"width:1px\">"
      html <<     '&rarr;' if row[:op] == :changed
      html <<   '</td>'
      html <<   "<td class=\"#{class_}\">"
      html <<     '<code>'
      html <<       sanitize(row[:after_value].to_s)
      html <<     '</code>'
      html <<   '</td>'
      html << '</tr>'
    end
    html << '</table>'
    raw(html.string)
  end

end