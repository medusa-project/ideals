module ItemsHelper

  ##
  # @param metadata_profile [MetadataProfile]
  # @return [String] Form elements for the advanced search form, excluding the
  #                  outer `form` element.
  #
  def advanced_search_form(metadata_profile = MetadataProfile.default)
    mp_elements = metadata_profile.elements.select(&:searchable).sort_by(&:position)
    html     = StringIO.new

    mp_elements.each do |mp_e|
      html << '<div class="form-group row">'
      html <<   label_tag("elements[#{mp_e.name}]",
                          mp_e.label,
                          class: "col-sm-3 col-form-label")
      html <<   '<div class="col-sm-9">'
      reg_e = mp_e.registered_element
      if reg_e.vocabulary
        options = [["Any", nil]] + reg_e.vocabulary.terms.map{ |t| [t.displayed_value, t.stored_value] }
        html << select_tag("elements[#{mp_e.name}]",
                           options_for_select(options),
                           class: "custom-select") # TODO: selected
      elsif reg_e.input_type == RegisteredElement::InputType::DATE
        html << '<div class="form-inline">'
        html <<   date_picker(month_select_name: "elements[#{mp_e.name}][month]",
                              day_select_name:   "elements[#{mp_e.name}][day]",
                              year_select_name:  "elements[#{mp_e.name}][year]",
                              selected_month:    0,
                              selected_day:      0,
                              selected_year:     0,
                              earliest_year:     Setting.integer(Setting::Key::EARLIEST_SEARCH_YEAR),
                              latest_year:       Time.now.year,
                              include_blanks:    true)
        html << '</div>'
      else
        html << text_field_tag("elements[#{mp_e.name}]",
                               sanitize(params["elements[#{mp_e.name}]"], tags: []),
                               class: "form-control")
      end
      html <<   '</div>'
      html << '</div>'
    end

    # Full Text
    html << '<div class="form-group row">'
    html <<   label_tag("full_text", "Full Text",
                        class: "col-sm-3 col-form-label")
    html <<   '<div class="col-sm-9">'
    html <<     text_field_tag("full_text",
                               params[:full_text],
                               class: "form-control")
    html <<   '</div>'
    html << '</div>'
    raw(html.string)
  end

  ##
  # @param embargo [Embargo] Optional.
  # @param index [Integer] Row index.
  # @return [String] HTML string.
  #
  def embargoes_form_card(embargo: nil, index: 0)
    selected_year = Time.now.year
    latest_year   = Time.now.year + 100

    html = StringIO.new
    html << '<div class="card mb-3">'
    html <<   '<div class="card-header">'
    html <<     '<div class="float-right">'
    html <<       '<button class="btn btn-outline-danger remove-embargo" type="button">'
    html <<         '<i class="fa fa-minus"></i> '
    html <<       '</button>'
    html <<     '</div>'
    html <<     '<div class="form-inline">'
    html <<       '<div class="form-check">'
    html <<         '<label class="mr-3">'
    html <<           radio_button_tag("embargoes[0][perpetual]", "true",
                                       embargo&.perpetual,
                                       class: 'form-check-input')
    html <<           "Never expires"
    html <<         '</label>'
    html <<       '</div>'
    html <<       '<div class="form-check">'
    html <<         '<label class="mr-2">'
    html <<           radio_button_tag("embargoes[0][perpetual]", "false",
                                       !embargo&.perpetual,
                                       class: 'form-check-input')
    html <<           "Expires at"
    html <<         '</label>'
    html <<       '</div>'

    if embargo&.expires_at && embargo.expires_at.year > latest_year
      selected_year = latest_year
    end
    html <<       date_picker(month_select_name: "embargoes[0][expires_at_month]",
                              day_select_name:   "embargoes[0][expires_at_day]",
                              year_select_name:  "embargoes[0][expires_at_year]",
                              selected_month:    embargo&.expires_at&.month,
                              selected_day:      embargo&.expires_at&.day,
                              selected_year:     selected_year,
                              latest_year:       Time.now.year + 100)
    html <<     '</div>'
    html <<   '</div>'
    html <<   '<div class="card-body">'
    html <<     '<div class="row">'
    html <<       '<div class="col-sm-4">'
    html <<         '<div class="form-group">'
    html <<           'Restrict'
    html <<           '<div class="form-check">'
    html <<             '<label>'
    html <<               radio_button_tag("embargoes[#{index}][kind]", Embargo::Kind::DOWNLOAD,
                                           (embargo&.kind == Embargo::Kind::DOWNLOAD),
                                           class: 'form-check-input')
    html <<               " Files Only"
    html <<             '</label>'
    html <<           '</div>'
    html <<           '<div class="form-check">'
    html <<             '<label>'
    html <<               radio_button_tag("embargoes[#{index}][kind]", Embargo::Kind::ALL_ACCESS,
                                           (embargo&.kind == Embargo::Kind::ALL_ACCESS),
                                           class: 'form-check-input')
    html <<               " All Access (files & metadata suppressed from public view)"
    html <<             '</label>'
    html <<           '</div>'
    html <<         '</div>'
    html <<       '</div>'
    html <<       '<div class="col-sm-8">'
    html <<         '<div class="form-group">'
    html <<           'Exempted User Groups'
    if embargo && embargo.user_groups.any?
      embargo.user_groups.each_with_index do |group, index|
        html << embargo_user_group_row(group: group, index: index)
      end
    else
      html << embargo_user_group_row
    end
    html <<           '<button class="btn btn-outline-success btn-sm add-user-group" type="button">'
    html <<             '<i class="fa fa-plus"></i>'
    html <<           '</button>'
    html <<         '</div>'
    html <<       '</div>'
    html <<     '</div>' # .row
    html <<     '<div class="form-group">'
    html <<       label_tag("embargoes[#{index}][reason]", "Reason")
    html <<       text_area_tag("embargoes[#{index}][reason]",
                                embargo&.reason,
                                class: "form-control")
    html <<     '</div>'
    html <<   '</div>'
    html << '</div>'
    raw(html.string)
  end

  ##
  # Renders a list of recently added items.
  #
  # N.B.: This produces markup similar to {ApplicationHelper#resource_list}, so
  # if the markup is changed here, it should be changed there too.
  #
  # @param items [Enumerable<Item>]
  # @return [String] HTML listing.
  #
  def recent_list(items)
    html = StringIO.new
    year = month = day = 0
    items.each do |item|
      item_year  = item.created_at.year
      item_month = item.created_at.month
      item_day   = item.created_at.day
      if item_year != year || item_month != month || item_day != day
        html << "<hr>" if year > 0
        html << "<h3>"
        html <<   item.created_at.strftime("%A, %B %-d")
        html << "</h3>"
      end
      year  = item_year
      month = item_month
      day   = item_day
      html << "<div class=\"media resource-list mb-3\">"
      html <<   "<div class=\"icon-thumbnail\">"
      html <<     link_to(item) do
        icon_for(item)
      end
      html <<   "</div>"
      html <<   "<div class=\"media-body\">"
      html <<     "<h5 class=\"mt-0 mb-0\">"
      html <<       link_to(item.title, item)
      html <<     "</h5>"

      config  = ::Configuration.instance
      creator = item.elements.
        select{ |e| e.name == config.elements[:creator] }.
        map(&:string).
        join("; ")
      date    = item.elements.
        select{ |e| e.name == config.elements[:date] }.
        map{ |e| e.string.to_i.to_s }.
        reject{ |e| e == "0" }.
        join("; ")
      info_parts  = []
      info_parts << creator if creator.present?
      info_parts << date if date.present?
      html       << info_parts.join(" &bull; ")
      html       << "<br><br>"

      html <<   "</div>"
      html << "</div>"
    end
    raw(html.string)
  end

  ##
  # Renders a list of reviewable {Item}s.
  #
  # @param items [Enumerable<Item>] Items grouped by unit and subgrouped by
  #        collection.
  # @param show_tree_headings [Boolean] Whether to show unit/collection tree
  #        headings.
  # @return [String] HTML listing.
  # @see ApplicationHelper#resource_list
  #
  def review_list(items, show_tree_headings: true)
    html = form_tag(items_process_review_path, method: :post, id: "review-form") do
      form = StringIO.new
      form << hidden_field_tag("verb", ""); # value set to approve or reject by JS
      prev_unit = prev_collection = nil
      items.each do |item|
        if show_tree_headings
          # Unit heading
          unit = item.effective_primary_unit
          if prev_unit != unit
            form << "<h2>"
            form << icon_for(unit) + ' ' + unit.title
            form << "</h2>"
          end
          # Collection heading
          collection = item.effective_primary_collection
          if prev_collection != collection
            form << "<h3 class=\"ml-3\">"
            form <<   "&#8627; "
            form << icon_for(collection) + ' ' + collection.title
            form << "</h3>"
          end
        end
        form << "<div class=\"media resource-list mb-3 ml-3\">"
        form <<   "<div class=\"check\">"
        form <<     check_box_tag("items[]", item.id)
        form <<   "</div>"
        form <<   "<div class=\"thumbnail ml-2\">"
        form <<     link_to(item) do
          icon_for(item)
        end
        form <<   "</div>"
        form <<   "<div class=\"media-body\">"
        form <<     "<h5 class=\"mt-0 mb-0\">"
        form <<       link_to(item.title, item)
        form <<     "</h5>"
        # Submitter
        form <<     "Submitted by "
        form <<     link_to(item.submitter.becomes(User)) do
          icon_for(item.submitter) + " " + item.submitter.name
        end
        form <<     " on "
        form <<     item.created_at.strftime("%B %d, %Y")
        form <<   "</div>"
        form << "</div>"
        prev_unit       = unit
        prev_collection = collection
      end
      raw(form.string)
    end
    raw(html)
  end


  private

  def embargo_user_group_row(group: nil, index: 0)
    html  = StringIO.new
    html << "<div class=\"user-group form-inline mb-2\" "\
                  "style=\"#{group ? "" : "display: none"}\">"
    html <<   select_tag("embargoes[#{index}][user_group_ids][]",
                         options_for_select(UserGroup.all.order(:name).pluck(:name, :id), group&.id),
                         disabled: group.blank?,
                         class:    "custom-select",
                         style:    "width: 90%")
    html <<   '<button class="btn btn-outline-danger btn-sm ml-2 remove-user-group" type="button">'
    html <<     '<i class="fa fa-minus"></i>'
    html <<   '</button>'
    html << '</div>'
    raw(html.string)
  end

end