module ItemsHelper

  ##
  # @param metadata_profile [MetadataProfile]
  # @return [String] Form elements for the advanced search form, excluding the
  #                  outer `form` element.
  #
  def advanced_search_form(metadata_profile = current_institution&.default_metadata_profile || MetadataProfile.global)
    mp_elements = metadata_profile.elements.select(&:searchable).sort_by(&:position)
    html        = StringIO.new

    mp_elements.each do |mp_e|
      html << '<div class="mb-3 row">'
      html <<   label_tag("elements[#{mp_e.name}]",
                          mp_e.label,
                          class: "col-sm-3 col-form-label")
      html <<   '<div class="col-sm-9">'
      reg_e = mp_e.registered_element
      vocab = reg_e.vocabulary
      if vocab
        options = [["Any", nil]] + vocab.vocabulary_terms.map{ |t| [t.displayed_value, t.stored_value] }
        html << select_tag("elements[#{mp_e.name}]",
                           options_for_select(options),
                           class: "form-select") # TODO: selected
      elsif reg_e.input_type == RegisteredElement::InputType::DATE
        earliest_year = current_institution.earliest_search_year
        html << '<ul class="nav nav-pills nav-justified date-search-type" role="tablist">'
        html <<   '<li class="nav-item" role="presentation">'
        html <<     '<button class="nav-link active" id="exact-date-tab" '\
                             'data-bs-toggle="pill" data-bs-target="#exact-date" '\
                             'role="tab" type="button" aria-controls="exact-date" '\
                             'aria-selected="true">'
        html <<       'Exact Date'
        html <<     '</a>'
        html <<   '</li>'
        html <<   '<li class="nav-item" role="presentation">'
        html <<     '<button class="nav-link" id="date-range-tab" '\
                             'data-bs-toggle="pill" data-bs-target="#date-range" '\
                             'role="tab" type="button" aria-controls="date-range" '\
                             'aria-selected="false">'
        html <<       'Date Range'
        html <<     '</a>'
        html <<   '</li>'
        html << '</ul>'
        html << '<div class="tab-content">'
        html <<   '<div class="tab-pane fade show active" id="exact-date" '\
                        'role="tabpanel" aria-labelledby="exact-date-tab">'
        html <<     '<div class="form-inline">'
        html <<       date_picker(month_select_name: "elements[#{mp_e.name}][month]",
                                  day_select_name:   "elements[#{mp_e.name}][day]",
                                  year_select_name:  "elements[#{mp_e.name}][year]",
                                  selected_month:    0,
                                  selected_day:      0,
                                  selected_year:     0,
                                  earliest_year:     earliest_year,
                                  latest_year:       Time.now.year,
                                  include_blanks:    true)
        html <<     '</div>'
        html <<   '</div>'
        html <<   '<div class="tab-pane fade" id="date-range" role="tabpanel" '\
                        'aria-labelledby="date-range-tab">'
        html <<     '<div class="form-inline">'
        html <<       '<label class="form-label">From:</label>'
        html <<       date_picker(month_select_name: "elements[#{mp_e.name}][from_month]",
                                  day_select_name:   "elements[#{mp_e.name}][from_day]",
                                  year_select_name:  "elements[#{mp_e.name}][from_year]",
                                  selected_month:    0,
                                  selected_day:      0,
                                  selected_year:     0,
                                  earliest_year:     earliest_year,
                                  latest_year:       Time.now.year,
                                  include_blanks:    true)
        html <<     '</div>'
        html <<     '<div class="form-inline">'
        html <<       '<label class="form-label">To:</label>'
        html <<       date_picker(month_select_name: "elements[#{mp_e.name}][to_month]",
                                  day_select_name:   "elements[#{mp_e.name}][to_day]",
                                  year_select_name:  "elements[#{mp_e.name}][to_year]",
                                  selected_month:    0,
                                  selected_day:      0,
                                  selected_year:     0,
                                  earliest_year:     earliest_year,
                                  latest_year:       Time.now.year,
                                  include_blanks:    true)
        html <<     '</div>'
        html <<   '</div>'
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
    html << '<div class="mb-3 row">'
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
  # @param institution [Institution] Required if `embargo` is not provided.
  # @param index [Integer] Row index.
  # @return [String] HTML string.
  #
  def embargoes_form_card(embargo: nil, institution: nil, index: 0)
    institution ||= embargo&.item&.institution
    selected_year = Time.now.year
    latest_year   = selected_year + 100
    html          = StringIO.new
    html << '<div class="card mb-3">'
    html <<   '<div class="card-header pt-3">'
    html <<     '<div class="float-end">'
    html <<       '<button class="btn btn-sm btn-outline-danger remove-embargo" type="button">'
    html <<         '<i class="fa fa-minus"></i> Remove Embargo'
    html <<       '</button>'
    html <<     '</div>'
    html <<     '<div class="form-inline">'
    html <<       '<div class="form-check">'
    html <<         '<label class="me-3">'
    html <<           radio_button_tag("embargoes[0][perpetual]", "true",
                                       embargo&.perpetual,
                                       class: 'form-check-input')
    html <<           "Never expires"
    html <<         '</label>'
    html <<       '</div>'
    html <<       '<div class="form-check">'
    html <<         '<label class="me-2">'
    html <<           radio_button_tag("embargoes[0][perpetual]", "false",
                                       !embargo&.perpetual,
                                       class: 'form-check-input')
    html <<           "Expires at:"
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
    html <<       '<div class="col-sm-5">'
    html <<         '<div class="mb-3">'
    html <<           'Restrict'
    html <<           '<div class="form-check">'
    html <<             '<label>'
    html <<               radio_button_tag("embargoes[#{index}][kind]", Embargo::Kind::DOWNLOAD,
                                           (embargo&.kind == Embargo::Kind::DOWNLOAD || !embargo),
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
    html <<       '<div class="col-sm-7">'
    html <<         '<div class="mb-3">'
    html <<           'Exempted User Groups<br>'
    if embargo && embargo.user_groups.any?
      embargo.user_groups.each_with_index do |group, index2|
        html << embargo_user_group_row(institution: institution, group: group, index: index2)
      end
    else
      html << embargo_user_group_row(institution: institution)
    end
    html <<           '<button class="btn btn-outline-success btn-sm add-user-group" type="button">'
    html <<             '<i class="fa fa-plus"></i>'
    html <<           '</button>'
    html <<         '</div>'
    html <<       '</div>'
    html <<     '</div>' # .row
    html <<     '<div class="row">'
    html <<       '<div class="col-sm-6">'
    html <<         label_tag("embargoes[#{index}][reason]", "Private Reason")
    html <<         text_area_tag("embargoes[#{index}][reason]",
                                  embargo&.reason,
                                  rows:  3,
                                  class: "form-control")
    html <<       '</div>'
    html <<       '<div class="col-sm-6">'
    html <<         label_tag("embargoes[#{index}][public_reason]", "Public Reason")
    html <<         text_area_tag("embargoes[#{index}][public_reason]",
                                  embargo&.public_reason,
                                  rows:  3,
                                  class: "form-control")
    html <<       '</div>'
    html <<     '</div>'
    html <<   '</div>'
    html << '</div>'
    raw(html.string)
  end

  ##
  # Renders a list of recently added items.
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
      html << resource_list_row(item) # ApplicationHelper
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
            form << "<h3 class=\"ms-3\">"
            form <<   "&#8627; "
            form << icon_for(collection) + ' ' + collection.title
            form << "</h3>"
          end
        end
        form << "<div class=\"d-flex resource-list mb-3 ms-3\">"
        form <<   "<div class=\"check\">"
        form <<     check_box_tag("items[]", item.id)
        form <<   "</div>"
        form <<   "<div class=\"flex-shrink-0 icon-thumbnail ms-2\">"
        form <<     link_to(item) do
          icon_for(item)
        end
        form <<   "</div>"
        form <<   "<div class=\"flex-grow-1 ms-3\">"
        form <<     "<h5 class=\"mt-0 mb-0\">"
        form <<       link_to(item.title, item)
        form <<     "</h5>"
        # Submitter
        form <<     "Submitted by "
        form <<     link_to(item.submitter) do
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

  ##
  # Renders a submission list.
  #
  # @param items [Enumerable<Item>]
  # @return [String] HTML listing.
  #
  def submission_list(items)
    html = StringIO.new
    items.each do |item|
      html << submission_list_row(item)
    end
    raw(html.string)
  end

  ##
  # @param item [Item]
  # @return [String] HTML string.
  #
  def submission_list_row(item)
    thumb    = thumbnail_for(item)
    item_url = item_url(item)
    title    = item.title.present? ? item.title : "(Untitled)"
    html     = StringIO.new
    html << "<div class=\"d-flex resource-list mb-3\">"
    if thumb
      html <<   "<div class=\"flex-shrink-0 image-thumbnail\">"
      html <<     link_to(item_url) do
        thumb
      end
    else
      html <<   "<div class=\"flex-shrink-0 icon-thumbnail\">"
      html <<     link_to(item_url) do
        icon_for(item)
      end
    end
    html <<   "</div>"
    html <<   "<div class=\"flex-grow-1 ms-3\">"
    html <<     "<h5 class=\"mt-0 mb-0\">"
    html <<       link_to(title, item_url)
    html <<     "</h5>"
    if item.submitter
      html << link_to(item.submitter) do
        icon_for(item.submitter) + " " + item.submitter.name
      end
      html << " &bull; "
      html << local_time(item.created_at)
    end
    html <<   "</div>"
    html << "</div>"
    html.string
  end


  private

  def embargo_user_group_row(institution:, group: nil, index: 0)
    html  = StringIO.new
    html << "<div class=\"user-group input-group mb-2\" "\
                  "style=\"#{group ? "" : "display: none"}\">"
    html <<   select_tag("embargoes[#{index}][user_group_ids][]",
                         options_for_select(institution.user_groups.order(:name).pluck(:name, :id), group&.id),
                         disabled: group.blank?,
                         class:    "form-select",
                         style:    "width: 90%")
    html <<   '<button class="btn btn-outline-danger btn-sm remove-user-group" type="button">'
    html <<     '<i class="fa fa-minus"></i>'
    html <<   '</button>'
    html << '</div>'
    raw(html.string)
  end

end
