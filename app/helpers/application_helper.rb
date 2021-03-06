module ApplicationHelper

  MAX_PAGINATION_LINKS = 5

  ##
  # Formats a boolean for display.
  #
  # @param boolean [Boolean]
  # @param style [Symbol] `:check` or `:word`
  # @param invert_color [Boolean]
  # @param omit_color [Boolean]
  # @return [String]
  #
  def boolean(boolean, style: :check, invert_color: false, omit_color: false)
    if style == :check
      content = boolean ? '&check;' : '&times;'
      boolean = !boolean if invert_color
      class_  = boolean ? 'text-success' : 'text-danger'
      class_  = 'text-light' if omit_color
      html    = "<span class=\"#{class_}\">#{content}</span>"
    else
      content = boolean ? 'YES' : 'NO'
      boolean = !boolean if invert_color
      class_  = boolean ? 'badge-success' : 'badge-danger'
      class_  = 'badge-light' if omit_color
      html    = "<span class=\"badge #{class_}\">#{content}</span>"
    end
    raw(html)
  end

  ##
  # Returns the institution whose FQDN corresponds to the value of the
  # `X-Forwarded-Host` header. This header should always be present in demo and
  # production, but not in development or test, where a fallback is used
  # instead.
  #
  # @return [Institution]
  #
  def current_institution
    Institution.find_by_fqdn(request.host) || Institution.find_by_default(true)
  end

  ##
  # @param month_select_name [String]
  # @param day_select_name [String]
  # @param year_select_name [String]
  # @param selected_month [Integer]
  # @param selected_day [Integer]
  # @param selected_year [Integer]
  # @param earliest_year [Integer]
  # @param latest_year [Integer]
  # @return [String]
  #
  def date_picker(month_select_name: "month",
                  day_select_name:   "day",
                  year_select_name:  "year",
                  selected_month:    Time.now.month,
                  selected_day:      Time.now.day,
                  selected_year:     Time.now.year,
                  earliest_year:     Time.now.year,
                  latest_year:       Time.now.year)
    m_options = (1..12).map{ |m| [Date::MONTHNAMES[m], m] }
    d_options = (1..31)
    y_options = (earliest_year..latest_year)

    html = StringIO.new
    html << "<div class='form-group date-picker'>"
    html <<   select_tag(month_select_name,
                         options_for_select(m_options, selected_month),
                         class: "custom-select mr-1")
    html <<   select_tag(day_select_name,
                         options_for_select(d_options, selected_day),
                         class: "custom-select mr-1")
    html <<   select_tag(year_select_name,
                         options_for_select(y_options, selected_year),
                         class: "custom-select")
    html << "</div>"
    raw(html.string)
  end

  ##
  # @return [String]
  #
  def date_range_picker
    now       = Time.now
    m_options = (1..12)
    y_options = (Event.order(:happened_at).limit(1).pluck(:happened_at).first.year..now.year)

    html = StringIO.new
    html << "<div class='form-group mr-4 date-range-picker'>From:"
    html <<   select_tag("from_month", options_for_select(m_options),
                         class: "custom-select ml-1 mr-1")
    html <<   select_tag("from_year", options_for_select(y_options, selected: now.year),
                         class: "custom-select")
    html << "</div>"
    html << "<div class='form-group mr-4 date-range-picker'>To:"
    html <<   select_tag("to_month", options_for_select(m_options, selected: 12),
                         class: "custom-select ml-1 mr-1")
    html <<   select_tag("to_year", options_for_select(y_options, selected: now.year),
                         class: "custom-select")
    html << "</div>"
    html << submit_tag("Go",
                       class: "btn btn-primary",
                       data: { disable_with: false })
    raw(html.string)
  end

  ##
  # @param facets [Enumerable<Facet>]
  # @param permitted_params [ActionController::Parameters]
  # @return [String] HTML string.
  #
  def facets_as_cards(facets, permitted_params)
    return nil unless facets
    html = StringIO.new
    facets.select{ |f| f.terms.any? }.each do |facet|
      html << facet_card(facet, permitted_params)
    end
    raw(html.string)
  end

  ##
  # @param name [String] Field name.
  # @param icon [String] Font Awesome icon class.
  # @param container [Unit,Collection] Container a.k.a. owning object to limit
  #                                    results to.
  # @param container_field [String] Index field, such as
  #                                 {Item::IndexFields::PRIMARY_UNIT_ID},
  #                                 corresponding to `container`.
  # @param placeholder [String] Placeholder text.
  # @param submit_text [String] Text to put in the submit button.
  # @return [String] HTML div element without surrounding form.
  #
  def filter_field(name: "q",
                   icon: nil,
                   container: nil,
                   container_field: nil,
                   placeholder: nil,
                   submit_text: nil)
    html = StringIO.new
    html << hidden_field_tag(container_field, container.id) if container
    if icon
      html << "<div class=\"input-group-prepend input-group-text\">"
      html <<   "<i class=\"#{icon}\"></i>"
      html << "</div>"
    end
    html << search_field_tag(name, "",
                             placeholder: raw(placeholder),
                             'aria-label': 'Search',
                             class: 'form-control')
    if submit_text
      html << "<div class=\"input-group-append\">"
      html <<   submit_tag(submit_text,
                           name: "",
                           class: "btn btn-outline-primary")
      html << "</div>"
    end
    raw(html.string)
  end

  ##
  # @param entity [Object,Symbol] Any model object or class, or `:info` or
  #                               `:warning`.
  # @return [String] HTML icon tag.
  #
  def icon_for(entity)
    entity_class = entity.kind_of?(Class) ? entity : entity.class
    entity_class = entity_class.to_s
    case entity_class
    when "Bitstream"
      if entity.media_type.present?
        if entity.media_type.start_with?("audio/")
          icon = "far fa-file-audio"
        elsif entity.media_type.start_with?("image/")
          icon = "far fa-file-image"
        elsif entity.media_type.start_with?("video/")
          icon = "far fa-file-video"
        else
          case entity.media_type
          when "application/msword"
            icon = "far fa-file-word"
          when "application/octet-stream"
            icon = "far fa-file"
          when "application/postscript"
            icon = "far fa-file-image"
          when "application/pdf"
            icon = "far fa-file-pdf"
          when "application/vnd.ms-excel"
            icon = "far fa-file-excel"
          when "application/vnd.ms-powerpoint"
            icon = "far fa-file-powerpoint"
          when "application/vnd.openxmlformats-officedocument.presentationml.presentation"
            icon = "far fa-file-powerpoint"
          when "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            icon = "far fa-file-excel"
          when "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            icon = "far fa-file-word"
          when "application/x-rar-compressed"
            icon = "far fa-file-archive"
          when "application/x-tex"
            icon = "far fa-file-code"
          when "application/zip"
            icon = "far fa-file-archive"
          when "text/csv"
            icon = "far fa-file-alt"
          when "text/html"
            icon = "far fa-file-code"
          when "text/plain"
            icon = "far fa-file-alt"
          when "text/richtext"
            icon = "far fa-file-alt"
          when "text/xml"
            icon = "far fa-file-code"
          else
            icon = "far fa-file"
          end
        end
      else
        ext = File.extname(entity.original_filename).downcase.reverse.chomp(".").reverse
        case ext
        when "bmp", "gif", "jp2", "jpg", "jpeg", "png", "tif", "tiff", "wbmp", "xpm"
          icon = "far fa-file-image"
        when "aif", "aiff", "mid", "mp3", "ra", "ram", "wav"
          icon = "far fa-file-audio"
        when "avi", "flv", "mov", "mp4", "mpg", "qt", "ts", "wmv"
          icon = "far fa-file-video"
        when "pdf", "ps"
          icon = "far fa-file-pdf"
        when "doc", "docx"
          icon = "far fa-file-word"
        when "xls", "xlsx"
          icon = "far fa-file-excel"
        when "ppt", "pptx"
          icon = "far fa-file-powerpoint"
        when "7z", "bz2", "gz", "hqx", "rar", "tar", "tgz", "zip"
          icon = "far fa-file-archive"
        when "c", "cpp", "css", "h", "htm", "html", "js", "php", "pl", "py", "rb", "tex", "xml", "xsl"
          icon = "far fa-file-code"
        when "csv", "rtf", "tsv", "txt"
          icon = "far fa-file-alt"
        else
          icon = "far fa-file"
        end
      end
    when "Collection"
      icon = "far fa-folder-open"
    when "Institution"
      icon = "fa fa-university"
    when "Item"
      icon = "fa fa-cube"
    when "MetadataProfile", "SubmissionProfile"
      icon = "fa fa-list"
    when "RegisteredElement", "AscribedElement", "MetadataProfileElement",
        "SubmissionProfileElement"
      icon = "fa fa-tags"
    when "Symbol"
      case entity
      when :info
        icon = "fa fa-info-circle"
      else
        icon = "fa fa-exclamation-triangle"
      end
    when "Unit"
      icon = "fa fa-building"
    when "User", "LocalUser", "ShibbolethUser"
      icon = "fa fa-user"
    else
      icon = "fa fa-cube"
    end
    raw("<i class=\"#{icon}\"></i>")
  end

  ##
  # @param ascribed_elements [Enumerable<AscribedElement>]
  # @param profile [MetadataProfile] If provided, only
  #        {MetadataProfileElement#visible visible elements} are displayed.
  # @return [String] HTML definition list.
  #
  def metadata_as_dl(ascribed_elements, profile = nil)
    html = StringIO.new
    html << "<dl class=\"metadata\">"
    all_elements = profile ?
                       profile.elements.where(visible: true).order(:index) :
                       RegisteredElement.all.order(:label)
    all_elements.each do |element|
      matching_ascribed_elements =
          ascribed_elements.select{ |e| e.name == element.name }
      if matching_ascribed_elements.any?
        html << "<dt>"
        html <<   element.label
        html << "</dt>"
        html << "<dd>"
        if matching_ascribed_elements.length > 1
          html << "<ul>"
          matching_ascribed_elements.each do |asc_e|
            html << "<li>"
            html <<   sanitize(asc_e.string)
            html << "</li>"
          end
          html << "</ul>"
        else
          html << sanitize(matching_ascribed_elements.first.string)
        end
        html << "</dd>"
      end
    end
    html << "</dl>"
    raw(html.string)
  end

  ##
  # @param count [Integer] Total number of results. Note that this will be
  #              limited internally to {ElasticsearchClient::MAX_RESULT_WINDOW}
  #              to avoid overwhelming the search server.
  # @param page [Integer]
  # @param per_page [Integer]
  # @param permitted_params [ActionController::Parameters]
  # @param max_links [Integer]
  # @param start_arg [Symbol] Name of the `start` query argument.
  #
  def paginate(count:,
               page:,
               per_page:,
               permitted_params:,
               max_links: MAX_PAGINATION_LINKS,
               start_arg: :start)
    count = [count, ElasticsearchClient::MAX_RESULT_WINDOW].min
    return '' if count <= per_page
    num_pages  = (count / per_page.to_f).ceil
    first_page = [1, page - (max_links / 2.0).floor].max
    last_page  = [first_page + max_links - 1, num_pages].min
    first_page = last_page - max_links + 1 if
        last_page - first_page < max_links and num_pages > max_links
    prev_page  = [1, page - 1].max
    next_page  = [last_page, page + 1].min
    prev_start = (prev_page - 1) * per_page
    next_start = (next_page - 1) * per_page
    last_start = (num_pages - 1) * per_page
    remote     = false

    first_link = link_to(permitted_params.except(start_arg),
                         remote: remote, class: 'page-link', 'aria-label': 'First') do
      raw('<span aria-hidden="true">First</span>')
    end
    prev_link = link_to(permitted_params.merge(start_arg => prev_start),
                        remote: remote,
                        class: 'page-link',
                        'aria-label': 'Previous') do
      raw('<span aria-hidden="true">&laquo;</span>')
    end
    next_link = link_to(permitted_params.merge(start_arg => next_start),
                        remote: remote,
                        class: 'page-link',
                        'aria-label': 'Next') do
      raw('<span aria-hidden="true">&raquo;</span>')
    end
    last_link = link_to(permitted_params.merge(start_arg => last_start),
                        remote: remote,
                        class: 'page-link',
                        'aria-label': 'Last') do
      raw('<span aria-hidden="true">Last</span>')
    end

    # https://getbootstrap.com/docs/4.4/components/pagination/
    html = StringIO.new
    html << '<nav>'
    html <<   '<ul class="pagination">'
    html <<     sprintf('<li class="page-item %s">%s</li>',
                        page == first_page ? 'disabled' : '',
                        first_link)
    html <<     sprintf('<li class="page-item %s">%s</li>',
                        page == prev_page ? 'disabled' : '',
                        prev_link)

    (first_page..last_page).each do |p|
      start = (p - 1) * per_page
      page_link = link_to((start == 0) ? permitted_params.except(start_arg) :
                              permitted_params.merge(start_arg => start), class: 'page-link', remote: remote) do
        raw("#{p} #{(page == p) ?
                           '<span class="sr-only">(current)</span>' : ''}")
      end
      html << sprintf('<li class="page-item %s">%s</li>',
                      page == p ? 'active' : '',
                      page_link)

    end
    html << sprintf('<li class="page-item %s">%s</li>',
                    p == next_page ? 'disabled' : '',
                    next_link)
    html << sprintf('<li class="page-item %s">%s</li>',
                    p == last_page ? 'disabled' : '',
                    last_link)
    html <<   '</ul>'
    html << '</nav>'
    raw(html.string)
  end

  ##
  # Alias of {ApplicationController#policy}.
  #
  # @return [ApplicationPolicy] Policy class associated with the current
  #         controller.
  #
  def policy(entity)
    self.controller.policy(entity)
  end

  ##
  # Renders a resource/results list. The resources may be any {Describable}
  # such as {Item}s, {Collections}, etc.
  #
  # @param resources [Enumerable<Describable>]
  # @param primary_id [Integer] ID of a resource in `resources` to indicate as
  #                             "primary."
  # @param default_id [Integer] ID of a resource in `resources` to indicate as
  #                             "default."
  # @return [String] HTML listing.
  #
  def resource_list(resources, primary_id: nil, default_id: nil)
    html = StringIO.new
    resources.each do |resource|
      html << "<div class=\"media resource-list mb-3\">"
      html <<   "<div class=\"thumbnail\">"
      html <<     link_to(resource) do
                    icon_for(resource)
                  end
      html <<   "</div>"
      html <<   "<div class=\"media-body\">"
      html <<     "<h5 class=\"mt-0 mb-0\">"
      html <<       link_to(resource.title, resource)
      if primary_id == resource.id
        html <<     " <span class=\"badge badge-primary\">PRIMARY</span>"
      elsif default_id == resource.id
        html <<     " <span class=\"badge badge-primary\">DEFAULT</span>"
      end
      html <<     "</h5>"

      if resources.first.kind_of?(Item)
        config  = ::Configuration.instance
        creator = resource.elements.
            select{ |e| e.name == config.elements[:creator] }.
            map(&:string).
            join(", ")
        date    = resource.elements.
            select{ |e| e.name == config.elements[:date] }.
            map{ |e| Time.new(e.string).year.to_s }.
            reject{ |e| e == "0" }.
            join(", ")
        info_parts  = []
        info_parts << creator if creator.present?
        info_parts << date if date.present?
        html       << info_parts.join(" &bull; ")
      else
        html << "<br><br>"
      end

      html <<   "</div>"
      html << "</div>"
    end
    raw(html.string)
  end

  ##
  # Returns the status of a search or browse action, e.g. "Showing n of n
  # items".
  #
  # @param total_num_results [Integer]
  # @param start [Integer]
  # @param num_results_shown [Integer]
  # @param noun [String] Singular noun for what we are showing, e.g. "item",
  #                      "collection", etc.
  # @return [String]
  #
  def search_status(total_num_results, start, num_results_shown, noun)
    last = [total_num_results, start + num_results_shown].min
    raw(sprintf("Showing %d&ndash;%d of %s %s",
                start + 1, last,
                number_with_delimiter(total_num_results),
                (total_num_results == 1) ? noun : noun.pluralize))
  end

  ##
  # Returns a sort pulldown menu for the given metadata profile. If there are
  # no sortable elements in the profile, returns a zero-length string.
  #
  # @param metadata_profile [MetadataProfile]
  # @return [String] HTML form element
  #
  def sort_menu(metadata_profile)
    sortable_elements = metadata_profile.elements.where(sortable: true)

    html = StringIO.new
    if sortable_elements.any?
      html << '<select name="sort" class="custom-select">'
      html << '<option value="">Sort by Relevance</option>'

      # If there is an element in the ?sort= query, select that. Otherwise,
      # select the metadata profile's default sort element.
      selected_element = sortable_elements.
          find{ |e| e.registered_element.indexed_sort_field == params[:sort] }
      sortable_elements.each do |e|
        selected = (e == selected_element) ? 'selected' : ''
        html << "<option value=\"#{e.registered_element.indexed_sort_field}\" #{selected}>"
        html <<   "Sort by #{e.label}"
        html << '</option>'
      end
      html << '</select>'
    end
    raw(html.string)
  end

  def spinner
    # N.B.: this markup should be kept in sync with that of IDEALS.Spinner()
    # in JavaScript.
    raw('<div class="d-flex justify-content-center m-5">
      <div class="spinner-border" role="status">
        <span class="sr-only">Loading...</span>
      </div>
    </div>')
  end


  private

  ##
  # @param facet [Facet]
  # @param permitted_params [ActionController::Parameters]
  #
  def facet_card(facet, permitted_params)
    panel = StringIO.new
    panel << "<div class=\"card facet\" id=\"#{facet.field}\">"
    panel <<   "<h5 class=\"card-header\">#{facet.name}</h5>"
    panel <<     '<div class="card-body">'
    panel <<       '<ul>'
    facet.terms.each do |term|
      checked          = (permitted_params[:fq]&.include?(term.query)) ? "checked" : nil
      checked_params   = term.removed_from_params(permitted_params.deep_dup).except(:start)
      unchecked_params = term.added_to_params(permitted_params.deep_dup).except(:start)
      term_label       = truncate(term.label, length: 80)

      panel << '<li class="term">'
      panel <<   '<div class="checkbox">'
      panel <<     '<label>'
      query =        term.query.gsub('"', '&quot;')
      panel <<       "<input type=\"checkbox\" name=\"fq[]\" #{checked} "\
                         "data-query=\"#{query}\" "\
                         "data-checked-href=\"#{url_for(unchecked_params)}\" "\
                         "data-unchecked-href=\"#{url_for(checked_params)}\" "\
                         "value=\"#{query}\"> "
      panel <<         "<span class=\"term-name\">#{term_label}</span> "
      panel <<         "<span class=\"count\">#{term.count}</span>"
      panel <<     '</label>'
      panel <<   '</div>'
      panel << '</li>'
    end
    panel <<     '</ul>'
    panel <<   '</div>'
    panel << '</div>'
    raw(panel.string)
  end

end