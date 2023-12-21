# frozen_string_literal: true

module ApplicationHelper

  # These tags will not be filtered out when displaying user-entered HTML.
  # See {allowed_html_tags}.
  ALLOWED_HTML_TAGS           = %w(a b blockquote br dd dl dt em h1 h2 h3 h4 h5 h6 i li ol p pre q s small strong sub sup u ul)
  ALLOWED_HTML_TAG_ATTRIBUTES = %w(href title)
  CAPTCHA_SALT                = ::Configuration.instance.secret_key_base
  MAX_PAGINATION_LINKS        = 5

  ##
  # @return [String] Human-readable list of tags allowed in user-submitted
  #                  HTML.
  #
  def allowed_html_tags
    raw(ALLOWED_HTML_TAGS.map{ |t| "<code>#{t}</code>" }.join(", "))
  end

  ##
  # @return [String] The sitewide banner message, in a `div`.
  #
  def banner_message
    html    = StringIO.new
    message = Setting.string(Setting::Key::BANNER_MESSAGE)
    if message.present?
      case Setting.string(Setting::Key::BANNER_MESSAGE_TYPE)
      when "info"
        icon = "fa fa-info-circle"
      else
        icon = "fa fa-exclamation-triangle"
      end
      html << "<div id=\"sitewide-banner-message\" "\
                "class=\"alert alert-#{Setting.string(Setting::Key::BANNER_MESSAGE_TYPE)}\">"
      html <<   "<i class=\"#{icon}\"></i> "
      html <<   h(message)
      html << "</div>"
    end
    raw(html.string)
  end

  ##
  # Formats a boolean for display.
  #
  # @param boolean [Boolean]
  # @param style [Symbol] `:check` or `:word`
  # @param true_value [String]
  # @param false_value [String]
  # @param show_false [Boolean] Whether to show a false value.
  # @param invert_color [Boolean]
  # @param omit_color [Boolean]
  # @return [String]
  #
  def boolean(boolean,
              style: :check,
              true_value: "YES",
              false_value: "NO",
              show_false: true,
              invert_color: false,
              omit_color: false)
    return "" if !boolean && !show_false
    if style == :check
      content = boolean ? '&check;' : '&times;'
      boolean = !boolean if invert_color
      class_  = boolean ? 'text-success' : 'text-danger'
      class_  = 'text-light' if omit_color
      html    = "<span class=\"#{class_}\">#{content}</span>"
    else
      content = boolean ? true_value : false_value
      boolean = !boolean if invert_color
      class_  = boolean ? 'bg-success' : 'bg-danger'
      class_  = 'bg-light' if omit_color
      html    = "<span class=\"badge #{class_}\">#{content}</span>"
    end
    raw(html)
  end

  ##
  # Invoked from the layout to render the breadcrumbs.
  #
  # @param object [Breadcrumb] Model object that includes {Breadcrumb}.
  # @return [String] HTML string.
  #
  def breadcrumbs(object)
    # Most institution-scoped models should have an `institution` getter
    # linking them to their owning institution. If this institution is
    # different from the current institution host (which could only be the case
    # for sysadmins), we want to render the breadcrumbs a little differently,
    # with a notice that we are looking at something in a different
    # institution, and the first breadcrumb must always be that institution.
    object_institution = object.respond_to?(:institution) ?
                           object.institution : (object.kind_of?(Institution) ? object : nil)
    object_scope_matches_request_scope =
      (object_institution == current_institution) || !object_institution
    all_scopes_align   = object_institution == current_user&.institution &&
      object_institution == current_institution
    crumb_obj = object
    crumbs    = []
    loop do
      break unless crumb_obj
      if crumbs.any?
        case crumb_obj.to_s
        when "IndexPage"
          crumbs.unshift({label: "Index Pages", url: index_pages_path})
        when "Institution"
          crumbs.unshift({label: "All Institutions", url: institutions_path})
        when "Invitee"
          crumbs.unshift({label: "Invitees", url: invitees_path})
        when "MetadataProfile"
          crumbs.unshift({label: "Metadata Profiles", url: metadata_profiles_path})
        when "PrebuiltSearch"
          crumbs.unshift({label: "Prebuilt Searches", url: prebuilt_searches_path})
        when "SubmissionProfile"
          crumbs.unshift({label: "Submission Profiles", url: submission_profiles_path})
        when "Unit"
          crumbs.unshift({icon: icon_for(crumb_obj), label: "Academic Units", url: units_path})
        when "User"
          crumbs.unshift({label: "Users", url: users_path})
        when "UserGroup"
          crumbs.unshift({label: "User Groups", url: user_groups_path})
        when "Vocabulary"
          crumbs.unshift({label: "Vocabularies", url: vocabularies_path})
        else
          crumbs.unshift({icon:  icon_for(crumb_obj),
                          label: crumb_obj.breadcrumb_label,
                          url:   url_for(crumb_obj)})
        end
      else # the last crumb is never hyperlinked
        crumbs << {icon: icon_for(crumb_obj), label: crumb_obj.breadcrumb_label}
      end
      crumb_obj = crumb_obj.respond_to?(:breadcrumb_parent) ?
                    crumb_obj.breadcrumb_parent : nil
    end

    if object_institution && !all_scopes_align && !object.kind_of?(Institution)
      crumbs.unshift({ icon:  icon_for(object_institution),
                       label: object_institution.name,
                       url:   institution_path(object_institution) })
    end

    html = StringIO.new
    html << "<nav aria-label=\"breadcrumb\">"
    html <<   "<ol class=\"breadcrumb #{object_scope_matches_request_scope ? nil : "bg-warning" }\">"
    crumbs.each do |crumb|
      html << "<li class=\"breadcrumb-item\">"
      if crumb[:url]
        if crumb[:icon]
          html << link_to(crumb[:url]) do
            crumb[:icon] + " " + crumb[:label]
          end
        else
          html << link_to(crumb[:label], crumb[:url])
        end
      elsif crumb[:icon]
        html << crumb[:icon] + " " + crumb[:label]
      else
        html << crumb[:label]
      end
      html << "</li>"
    end
    html <<   "</ol>"
    html << "</nav>"
    raw(html.string)
  end

  ##
  # Returns CAPTCHA form elements. The elements are:
  #
  # * `honey_email`:         hidden via CSS and expected to remain unfilled
  # * `correct_answer_hash`: hashed salted correct answer
  # * `answer`:              client-supplied answer
  #
  # Input is checked on the server using {ApplicationController#check_captcha}.
  #
  # @return [Hash<Symbol,String>] Two-element hash with `label` and `field`
  #                               keys.
  #
  def captcha
    field_html  = StringIO.new
    number1     = rand(9)
    number2     = rand(9)
    answer_hash = Digest::MD5.hexdigest((number1 + number2).to_s + CAPTCHA_SALT)
    label_html  = label_tag(:answer, raw("What is #{number1} &plus; #{number2}?"),
                            class: "col-sm-3 col-form-label")
    field_html << text_field_tag(:honey_email, nil,
                                 placeholder: "Leave this field blank.",
                                 style:       "display: none") # honeypot field
    field_html << text_field_tag(:answer, nil, class: "form-control")
    field_html << hidden_field_tag(:correct_answer_hash, answer_hash)
    {
      label: raw(label_html),
      field: raw(field_html.string)
    }
  end

  ##
  # Returns the institution whose FQDN corresponds to the value of the
  # `X-Forwarded-Host` header. In global scope, there will be no such header,
  # in which case `nil` is returned.
  #
  # Note that there may be other institutions in a given context:
  #
  # 1. The institution to whom the current user (if available) belongs
  # 2. The institution to which the currently viewed entity (if any) belongs
  #
  # @return [Institution,nil]
  # @see institution_host?
  #
  def current_institution
    Institution.find_by_fqdn(request.host_with_port)
  end

  ##
  # @param month_select_name [String]
  # @param day_select_name [String]
  # @param year_select_name [String]
  # @param selected_month [Integer] Supply `0` to select the blank item if
  #                                 `include_blanks` is `true`.
  # @param selected_day [Integer]   Supply `0` to select the blank item if
  #                                 `include_blanks` is `true`.
  # @param selected_year [Integer]  Supply `0` to select the blank item if
  #                                 `include_blanks` is `true`.
  # @param earliest_year [Integer]
  # @param latest_year [Integer]
  # @param include_blanks [Boolean] Whether to include a blank year, month, &
  #                                 day.
  # @param extra_attrs [Hash] Extra attributes to insert into the outer tag.
  # @return [String]
  #
  def date_picker(month_select_name: "month",
                  day_select_name:   "day",
                  year_select_name:  "year",
                  selected_month:    Time.now.month,
                  selected_day:      Time.now.day,
                  selected_year:     Time.now.year,
                  earliest_year:     Time.now.year,
                  latest_year:       Time.now.year,
                  include_blanks:    false,
                  extra_attrs:       {})
    m_options = (1..12).map{ |m| [Date::MONTHNAMES[m], m] }
    d_options = (1..31)
    y_options = (earliest_year..latest_year)

    html = StringIO.new
    attrs = { class: "row mb-3 date-picker" }
    extra_attrs.each do |k, v|
      if attrs[k].present?
        attrs[k] = "#{attrs[k]} #{v}"
      else
        attrs[k] = v
      end
    end
    html << "<div #{attrs.map{ |k,v| "#{k}='#{v}'" }.join(" ")}>"
    html <<   "<div class=\"col\">"
    html <<     select_tag(month_select_name,
                           options_for_select(m_options, selected_month),
                           include_blank: include_blanks,
                           class: "form-select me-1")
    html <<   "</div>"
    html <<   "<div class=\"col\">"
    html <<     select_tag(day_select_name,
                           options_for_select(d_options, selected_day),
                           include_blank: include_blanks,
                           class: "form-select me-1")
    html <<   "</div>"
    html <<   "<div class=\"col\">"
    html <<     select_tag(year_select_name,
                           options_for_select(y_options, selected_year),
                           include_blank: include_blanks,
                           class: "form-select")
    html <<   "</div>"
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
    html << "<div class='row mb-2'>"
    html <<   '<label class="form-label">From:</label>'
    html <<   "<div class='col'>"
    html <<     select_tag("from_month", options_for_select(m_options),
                           class: "form-select ms-1 me-1")
    html <<   '</div>'
    html <<   "<div class='col'>"
    html <<     select_tag("from_year", options_for_select(y_options, selected: now.year),
                           class: "form-select")
    html <<   '</div>'
    html << "</div>"
    html << "<div class='row mb-3'>"
    html <<   '<label class="form-label">To:</label>'
    html <<   "<div class='col'>"
    html <<     select_tag("to_month", options_for_select(m_options, selected: 12),
                           class: "form-select ms-1 me-1")
    html <<   '</div>'
    html <<   "<div class='col'>"
    html <<     select_tag("to_year", options_for_select(y_options, selected: now.year),
                           class: "form-select")
    html <<   '</div>'
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
  # @param submit_text [String] Text to put in the submit button. If omitted,
  #                             a submit button will not be appended.
  # @return [String] HTML `div` element without surrounding form.
  #
  def filter_field(name:            "q",
                   icon:            nil,
                   container:       nil,
                   container_field: nil,
                   placeholder:     nil,
                   submit_text:     nil)
    html = StringIO.new
    html << hidden_field_tag(container_field, container.id) if container
    if icon
      html << "<div class=\"input-group-prepend input-group-text\">"
      html <<   "<i class=\"#{icon}\"></i>"
      html << "</div>"
    end
    html << search_field_tag(name,
                             params[name.to_sym],
                             placeholder:  raw(placeholder),
                             'aria-label': "Search",
                             class:        "form-control")
    if submit_text
      html << submit_tag(submit_text,
                         name: "",
                         class: "btn btn-outline-primary")
    end
    raw(html.string)
  end

  ##
  # @return [String]
  #
  def google_analytics_tags
    # Most routes on which these tags would be displayed are scoped to an
    # institution. But for e.g. global pages which aren't scoped, use UIUC's
    # tag.
    institution = current_institution || Institution.find_by_key("uiuc")
    id          = institution&.google_analytics_measurement_id
    if id.present?
      return raw("<script async src=\"https://www.googletagmanager.com/gtag/js?id=#{id}\"></script>
      <script>
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', '#{id}');
      </script>")
    end
    nil
  end

  ##
  # Renders a help button triggering pop-up help.
  #
  # N.B.: this uses a Bootstrap popover which must be initialized manually in
  # JavaScript. This is already done on page load, but if this button is being
  # rendered into XHR-loaded content, you will need to initialize it manually
  # using `IDEALS.EnablePopovers()`.
  #
  # @param text [String] Help text.
  # @return [String]     Help button HTML.
  #
  def help_button(text)
    html = "<a tabindex=\"0\" role=\"button\" "\
        "data-bs-toggle=\"popover\" data-bs-trigger=\"focus\" "\
        "data-bs-placement=\"bottom\" "\
        "data-bs-content=\"#{text.gsub('"', "&quot;")}\"><i class=\"fa fa-question-circle\"></i></a>"
    raw(html)
  end

  ##
  # @param entity [Object]
  # @return [String] Series of Highwire Press meta tags.
  # @see https://scholar.google.no/intl/en/scholar/inclusion.html#indexing
  #
  def highwire_meta_tags(entity)
    html = StringIO.new
    html << "<meta name=\"citation_public_url\" "\
              "content=\"#{entity.handle&.permanent_url || polymorphic_url(entity)}\">\n"
    if entity.kind_of?(Item)
      entity.bitstreams.
        select{ |b| b.bundle == Bitstream::Bundle::CONTENT &&
          b.effective_key &&
          b.format &&
          b.format.media_types.include?("application/pdf") }.each do |bs|
        bs_authorized = true
        entity.current_embargoes.each do |embargo|
          unless current_user && embargo.exempt?(user:            current_user,
                                                 client_hostname: request_context.client_hostname,
                                                 client_ip:       request_context.client_ip)
            bs_authorized = false
            break
          end
        end
        if bs_authorized
          # Google Scholar needs a stable URL, it wants to see a .pdf
          # extension, and it doesn't want to follow redirects. Our only choice
          # is to proxy the bitstream's data.
          url = item_bitstream_data_url(bs.item, bs, format: bs.filename.split(".").last)
          html << "<meta name=\"citation_pdf_url\" content=\"#{url}\">\n"
        end
      end
    end
    # Find all registered elements that have Highwire mappings.
    reg_elements = entity.effective_metadata_profile.elements.
      where(visible: true).
      order(:position).
      map(&:registered_element).
      select{ |e| e.highwire_mapping.present? }
    reg_elements.each do |reg_e|
      entity.elements.
          select{ |e| e.name == reg_e.name }.
          sort_by(&:position).
          each do |asc_e|
        value = sanitize(asc_e.string, tags: [])
        html << "<meta name=\"#{reg_e.highwire_mapping}\" content=\"#{value}\">\n"
      end
    end
    raw(html.string)
  end

  ##
  # @param entity [Object,Symbol] Any model object or class, or the following
  #                               symbols: `:download`, `:help`, `:info`,
  #                               `:warning`.
  # @return [String] HTML icon tag.
  #
  def icon_for(entity)
    entity_class = entity.kind_of?(Class) ? entity : entity.class
    entity_class = entity_class.to_s
    icon         = nil
    case entity_class
    when "Bitstream"
      format = entity.format
      icon   = "far #{format.icon}" if format
    when "Collection"
      icon = "far fa-folder-open"
    when "ElementNamespace"
      icon = "fa fa-code"
    when "Event"
      icon = "fa fa-calendar-alt"
    when "FileFormat"
      icon = "fa fa-file"
    when "Import"
      icon = "fa fa-upload"
    when "IndexPage"
      icon = "far fa-file-alt"
    when "Invitee"
      icon = "fa fa-user-plus"
    when "Institution"
      icon = "fa fa-university"
    when "Item"
      icon = "fa fa-cube"
      if entity.kind_of?(Item)
        bs = entity.representative_bitstream
        if bs
          format = bs.format
          icon   = format.icon if format
        end
      end
    when "Message"
      icon = "fa fa-envelope"
    when "MetadataProfile", "SubmissionProfile"
      icon = "fa fa-list"
    when "PrebuiltSearch"
      icon = "fa fa-search"
    when "RegisteredElement", "AscribedElement", "MetadataProfileElement",
        "SubmissionProfileElement"
      icon = "fa fa-tags"
    when "Setting"
      icon = "fa fa-cog"
    when "Symbol"
      case entity
      when :delete
        icon = "fa fa-trash-can"
      when :download
        icon = "fa fa-download"
      when :help
        icon = "fa fa-question-circle"
      when :info
        icon = "fa fa-info-circle"
      when :warning
        icon = "fa fa-exclamation-triangle"
      end
    when "Task"
      icon = "fa fa-forward"
    when "Unit"
      icon = "fa fa-building"
    when "User"
      icon = "fa fa-user"
    when "UserGroup"
      icon = "fa fa-users"
    when "Vocabulary"
      icon = "far fa-font"
    end
    icon = "fa fa-cube" if icon.nil?
    raw("<i class=\"#{icon}\"></i>")
  end

  def include_chart_library
    javascript_include_tag(asset_path("/chart.min.js"))
  end

  ##
  # @return [Boolean] Whether the current route/view is scoped to an
  #                   institution.
  # @see current_institution
  #
  def institution_host?
    Institution.exists?(fqdn: request.host_with_port)
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
    reg_elements = profile ?
                       profile.elements.where(visible: true).order(:position) :
                       RegisteredElement.where(institution: current_institution).order(:label)
    reg_elements.each do |element|
      matching_ascribed_elements = ascribed_elements.
          select{ |e| e.name == element.name }.
          sort_by(&:position)
      next if matching_ascribed_elements.empty?
      html << "<dt>"
      html <<   element.label
      html << "</dt>"
      html << "<dd>"
      if matching_ascribed_elements.length > 1
        html << "<ul>"
        matching_ascribed_elements.each do |asc_e|
          html << "<li>"
          html <<   sanitize(asc_e.string,
                             tags:       ApplicationHelper::ALLOWED_HTML_TAGS,
                             attributes: ApplicationHelper::ALLOWED_HTML_TAG_ATTRIBUTES)
          html << "</li>"
        end
        html << "</ul>"
      else
        html << sanitize(matching_ascribed_elements.first.string,
                         tags:       ApplicationHelper::ALLOWED_HTML_TAGS,
                         attributes: ApplicationHelper::ALLOWED_HTML_TAG_ATTRIBUTES)
      end
      html << "</dd>"
    end
    html << "</dl>"
    raw(html.string)
  end

  ##
  # @param ascribed_elements [Enumerable<AscribedElement>]
  # @param profile [MetadataProfile] If provided, only
  #        {MetadataProfileElement#visible visible elements} are displayed.
  # @return [String] Series of HTML meta tags.
  #
  def metadata_as_meta_tags(ascribed_elements, profile = nil)
    html = StringIO.new
    reg_elements = profile ?
                     profile.elements.where(visible: true).order(:position) :
                     RegisteredElement.all.order(:label)
    reg_elements.each do |reg_element|
      ascribed_elements.
        select{ |e| e.name == reg_element.name }.
        sort_by(&:position).
        each do |asc_e|
        html << "<meta name=\"#{reg_element.name.gsub(":", ".")}\" "\
                  "content=\"#{sanitize(asc_e.string, tags: [])}\">"
      end
    end
    raw(html.string)
  end

  ##
  # @param count [Integer] Total number of results. Note that this will be
  #              limited internally to {OpenSearchIndex::MAX_RESULT_WINDOW}
  #              to avoid overwhelming the search server.
  # @param page [Integer]
  # @param per_page [Integer]
  # @param permitted_params [ActionController::Parameters]
  # @param max_links [Integer]
  #
  def paginate(count:,
               page:,
               per_page:,
               permitted_params:,
               max_links: MAX_PAGINATION_LINKS)
    count = [count, OpenSearchIndex::MAX_RESULT_WINDOW].min
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

    first_link = link_to(permitted_params.except(:start),
                         remote: remote, class: 'page-link', 'aria-label': 'First') do
      raw('<span aria-hidden="true">First</span>')
    end
    prev_link = link_to(permitted_params.merge(start: prev_start),
                        remote: remote,
                        class: 'page-link',
                        'aria-label': 'Previous') do
      raw('<span aria-hidden="true">&laquo;</span>')
    end
    next_link = link_to(permitted_params.merge(start: next_start),
                        remote: remote,
                        class: 'page-link',
                        'aria-label': 'Next') do
      raw('<span aria-hidden="true">&raquo;</span>')
    end
    last_link = link_to(permitted_params.merge(start: last_start),
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
      page_link = link_to((start == 0) ? permitted_params.except(:start) :
                              permitted_params.merge(start: start), class: 'page-link', remote: remote) do
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
  # Renders a resource/results list.
  #
  # @param resources [Enumerable<Describable,Unit,Collection>]
  # @param primary_id [Integer] ID of a resource in `resources` to indicate as
  #                             primary.
  # @param use_resource_host [Boolean]
  # @param show_institution [Boolean]
  # @return [String] HTML listing.
  #
  def resource_list(resources,
                    primary_id:        nil,
                    use_resource_host: true,
                    show_institution:  false)
    html = StringIO.new
    resources.each do |resource|
      html << resource_list_row(resource,
                                primary:           (primary_id == resource.id),
                                use_resource_host: use_resource_host,
                                show_institution:  show_institution)
    end
    raw(html.string)
  end

  ##
  # @param resource [Describable]
  # @param primary [Boolean] Whether to mark the resource as primary.
  # @param use_resource_host [Boolean]
  # @param show_institution [Boolean]
  # @return [String] HTML string.
  #
  def resource_list_row(resource,
                        primary:           false,
                        use_resource_host: true,
                        show_institution:  false)
    embargoed_item = resource.kind_of?(Item) &&
      resource.embargoed_for?(user:            current_user,
                              client_hostname: request_context.client_hostname,
                              client_ip:       request_context.client_ip)
    thumb          = thumbnail_for(resource)
    if use_resource_host
      resource_url = polymorphic_url(resource, host: resource.institution.fqdn)
    else
      resource_url = polymorphic_url(resource)
    end
    html           = StringIO.new
    html << "<div class=\"d-flex resource-list mb-3\">"
    if embargoed_item
      html <<   "<div class=\"flex-shrink-0 icon-thumbnail\">"
      html <<     '<i class="fa fa-lock"></i>'
    elsif thumb
      html <<   "<div class=\"flex-shrink-0 image-thumbnail\">"
      html <<     link_to(resource_url) do
        thumb
      end
    else
      html <<   "<div class=\"flex-shrink-0 icon-thumbnail\">"
      html <<     link_to(resource_url) do
        icon_for(resource)
      end
    end
    html <<   "</div>"
    html <<   "<div class=\"flex-grow-1 ms-3\">"
    html <<     "<h5 class=\"mt-0 mb-0\">"
    if embargoed_item
      html <<     resource.title
    else
      html <<     link_to(resource.title, resource_url)
    end

    if primary
      html <<     " <span class=\"badge text-bg-primary\">PRIMARY</span>"
    end
    if embargoed_item
      html <<     " <span class=\"badge text-bg-danger\">EMBARGOED</span>"
    end
    html <<     "</h5>"

    if resource.kind_of?(Item)
      author = resource.authors.map(&:string).join("; ")
      date   = resource.elements.
        select{ |e| e.name == resource.institution.date_approved_element.name }.
        map{ |e| e.string.to_i.to_s }.
        reject{ |e| e == "0" }.
        join("; ")
      info_parts  = []
      info_parts << author if author.present?
      info_parts << date if date.present?
      html       << info_parts.join(" &bull; ")
      if show_institution
        html << "<br>"
        html << "<span class=\"institution\">"
        html <<   icon_for(resource.institution)
        html <<   " "
        html <<   resource.institution.name
        html << "</span>"
      end
      html << "<br><br>"
    elsif resource.kind_of?(Collection) || resource.kind_of?(Unit)
      html << resource.short_description
    end

    html <<   "</div>"
    html << "</div>"
    html.string
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
    return "No #{noun.pluralize} to show" if start > total_num_results
    last = [total_num_results, start + num_results_shown].min
    raw(sprintf("Showing %d&ndash;%d of %s %s",
                start + 1, last,
                number_with_delimiter(total_num_results),
                (total_num_results == 1) ? noun : noun.pluralize))
  end

  ##
  # Returns a sort <select> menu for the given metadata profile. If there are
  # no sortable elements in the profile, an empty string is returned.
  #
  # @param metadata_profile [MetadataProfile]
  # @return [String] HTML form element.
  #
  def sort_menu(metadata_profile = current_institution&.default_metadata_profile || MetadataProfile.global)
    results_params    = params.permit(Search::RESULTS_PARAMS)
    sortable_elements = metadata_profile.elements.where(sortable: true)
    html              = StringIO.new
    if sortable_elements.any?
      # Select menu
      html << '<select name="sort" class="form-select">'
      html <<   '<optgroup label="Sort By&hellip;">'
      html <<     '<option value="">Relevance</option>'

      # If there is an element in the ?sort= query, select that. Otherwise,
      # select the metadata profile's default sort element.
      selected_element = sortable_elements.
          find{ |e| e.registered_element.indexed_sort_field == results_params[:sort] }
      sortable_elements.each do |e|
        selected = (e == selected_element) ? 'selected' : ''
        html <<   "<option value=\"#{e.registered_element.indexed_sort_field}\" #{selected}>"
        html <<     e.label
        html <<   '</option>'
      end
      html <<   '</optgroup>'
      html << '</select>'

      # Ascending/descending radios
      desc = results_params[:direction] == "desc"
      html << '<div class="btn-group btn-group-toggle ms-2" data-bs-toggle="buttons">'
      html <<   "<label class=\"btn btn-default btn-outline-primary #{!desc ? "active" : ""}\">"
      html <<     "<input type=\"radio\" name=\"direction\" value=\"asc\" autocomplete=\"off\" #{!desc ? "checked" : ""}> &uarr;"
      html <<   '</label>'
      html <<   "<label class=\"btn btn-default btn-outline-primary #{desc ? "active" : ""}\">"
      html <<     "<input type=\"radio\" name=\"direction\" value=\"desc\" autocomplete=\"off\" #{desc ? "checked" : ""}> &darr;"
      html <<   '</label>'
      html << '</div>'
    end
    raw(html.string)
  end

  def spinner
    # N.B.: this markup should be kept in sync with that of IDEALS.Spinner()
    # in JavaScript.
    raw('<div class="d-flex justify-content-center align-items-center" style="height: 100%">
      <div class="spinner-border text-secondary" role="status">
        <span class="sr-only">Loading&hellip;</span>
      </div>
    </div>')
  end

  ##
  # Returns a thumbnail image for an item. This is distinct from an {icon_for
  # icon}.
  #
  # @param item [Item]
  # @return [String,nil] HTML image tag or nil.
  #
  def thumbnail_for(item)
    if item.kind_of?(Item)
      bs = item.representative_bitstream
      if bs&.has_representative_image?
        url = DerivativeGenerator.new(bs).derivative_image_url(region:         :square,
                                                               size:           512,
                                                               generate_async: true)
        if url
          return raw("<img src=\"#{url}\" alt=\"Thumbnail for #{item.title}\"/>")
        end
      end
    end
    nil
  end

  ##
  # Gets and clears the toast (small closeable message dialog at the top right
  # of the page).
  #
  # @see toast!
  #
  def toast
    toast = session[:toast]
    session[:toast] = nil
    if toast
      toast.symbolize_keys!
      toast[:icon] = toast[:icon]&.to_sym
    end
    toast
  end

  ##
  # Sets the toast.
  #
  # @param title [String]
  # @param message [String]
  # @param icon [String,Symbol] Value to pass to {ApplicationHelper#icon_for},
  #                             typically either `:info` or `:warning`.
  # @return Enumerable<Hash> Enumerable of Hashes with the following keys:
  #                          `:title`, `:message`, `:icon`
  # @see toast
  #
  def toast!(title:, message:, icon: nil)
    icon ||= :info
    session[:toast] = { title: title, message: message, icon: icon }
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
      term_label       = truncate(sanitize(term.label, tags: []), length: 80)
      panel << '<li class="term">'
      panel <<   '<label>'
      query =      term.query.gsub('"', '&quot;')
      panel <<     "<input type=\"checkbox\" name=\"fq[]\" #{checked} "\
                       "data-query=\"#{query}\" "\
                       "data-checked-href=\"#{url_for(unchecked_params)}\" "\
                       "data-unchecked-href=\"#{url_for(checked_params)}\" "\
                       "value=\"#{query}\"> "
      panel <<       "<span class=\"term-name\">#{term_label}</span> "
      panel <<       "<span class=\"count\">#{term.count}</span>"
      panel <<   '</label>'
      panel << '</li>'
    end
    panel <<     '</ul>'
    panel <<   '</div>'
    panel << '</div>'
    raw(panel.string)
  end

end