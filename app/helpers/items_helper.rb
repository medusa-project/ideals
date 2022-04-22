module ItemsHelper

  ##
  # @return [String] Form elements for the advanced search form, excluding the
  #                  outer `form` element.
  #
  def advanced_search_form
    html = StringIO.new
    # Title
    html << '<div class="form-group row">'
    html <<   label_tag("title", "Title",
                        class: "col-sm-3 col-form-label")
    html <<   '<div class="col-sm-9">'
    html <<     text_field_tag("title", params[:"dc:title"],
                               class: "form-control")
    html <<   '</div>'
    html << '</div>'
    # Author
    html << '<div class="form-group row">'
    html <<   label_tag("author", "Author",
                        class: "col-sm-3 col-form-label")
    html <<   '<div class="col-sm-9">'
    html <<     text_field_tag("author", params[:"dc:creator"],
                               class: "form-control")
    html <<   '</div>'
    html << '</div>'
    # Advisor or Committee Member
    html << '<div class="form-group row">'
    html <<   label_tag("advisor", "Advisor or Committee Member",
                        class: "col-sm-3 col-form-label")
    html <<   '<div class="col-sm-9">'
    html <<     text_field_tag("advisor", params[:advisor],
                               class: "form-control")
    html <<     '<div class="form-check">'
    checked = (params[:advisor_type] == "advisor") ? "checked" : ""
    html <<       "<input class=\"form-check-input\" type=\"checkbox\" name=\"advisor_type\" value=\"advisor\" id=\"advisor-advisor\" #{checked}>"
    html <<       '<label class="form-check-label" for="advisor-advisor">'
    html <<         'Advisor (Masters) / Director of Research (Doctoral)'
    html <<       '</label>'
    html <<     '</div>'
    html <<     '<div class="form-check">'
    checked = (params[:advisor_type] == "committee_chair") ? "checked" : ""
    html <<       "<input class=\"form-check-input\" type=\"checkbox\" name=\"advisor_type\" value=\"committee_chair\" id=\"advisor-committee-chair\" #{checked}>"
    html <<       '<label class="form-check-label" for="advisor-committee-chair">'
    html <<         'Committee Chair (Doctoral)'
    html <<       '</label>'
    html <<     '</div>'
    html <<     '<div class="form-check">'
    checked = (params[:advisor_type] == "committee_member") ? "checked" : ""
    html <<       "<input class=\"form-check-input\" type=\"checkbox\" name=\"advisor_type\" value=\"committee_member\" id=\"advisor-committee-member\" #{checked}>"
    html <<       '<label class="form-check-label" for="advisor-committee-member">'
    html <<         'Committee Member (Doctoral)'
    html <<       '</label>'
    html <<     '</div>'
    html <<   '</div>'
    html << '</div>'
    # Degree Level
    html << '<div class="form-group row">'
    html <<   label_tag("degree_level", "Degree Level",
                        class: "col-sm-3 col-form-label")
    html <<   '<div class="col-sm-9">'
    html <<     select_tag("degree_level", options_for_select([["All", nil], %w(Master's Master's), %w(Doctoral Doctoral)]),
                           class: "custom-select")
    html <<   '</div>'
    html << '</div>'
    # Department
    html << '<div class="form-group row">'
    html <<   label_tag("department", "Department",
                        class: "col-sm-3 col-form-label")
    html <<   '<div class="col-sm-9">'
    html <<     text_field_tag("department", params[:department],
                               class: "form-control")
    html <<   '</div>'
    html << '</div>'
    # Date Deposited
    html << '<div class="form-group row">'
    html <<   label_tag("date_deposited", "Date Deposited",
                        class: "col-sm-3 col-form-label")
    html <<   '<div class="col-sm-9">'
    html <<     text_field_tag("date_deposited", params[:date_deposited],
                               class: "form-control")
    html <<   '</div>'
    html << '</div>'
    # Full Text
    html << '<div class="form-group row">'
    html <<   label_tag("full_text", "Full Text",
                        class: "col-sm-3 col-form-label")
    html <<   '<div class="col-sm-9">'
    html <<     text_field_tag("full_text", params[:full_text], class: "form-control")
    html <<     '<div class="form-check">'
    checked = (params[:full_text_type] == "full_text" || params[:full_text_type].blank?) ?
                "checked" : ""
    html <<       "<input class=\"form-check-input\" type=\"radio\" name=\"full_text_type\" value=\"full_text\" id=\"full-text-full-text\" #{checked}>"
    html <<       '<label class="form-check-label" for="full-text-full-text">'
    html <<         'Full Text'
    html <<       '</label>'
    html <<     '</div>'
    html <<     '<div class="form-check">'
    checked = (params[:full_text_type] == "abstract") ? "checked" : ""
    html <<       "<input class=\"form-check-input\" type=\"radio\" name=\"full_text_type\" value=\"abstract\" id=\"full-text-abstract\" #{checked}>"
    html <<       '<label class="form-check-label" for="full-text-abstract">'
    html <<         'Abstract'
    html <<       '</label>'
    html <<     '</div>'
    html <<     '<div class="form-check">'
    checked = (params[:full_text_type] == "keywords") ? "checked" : ""
    html <<       "<input class=\"form-check-input\" type=\"radio\" name=\"full_text_type\" value=\"keywords\" id=\"full-text-keywords\" #{checked}>"
    html <<       '<label class="form-check-label" for="full-text-keywords">'
    html <<         'Keywords'
    html <<       '</label>'
    html <<     '</div>'
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
    html <<       '<button class="btn btn-danger remove-embargo" type="button">'
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

    if embargo && embargo.expires_at.year > latest_year
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
    html <<               check_box_tag("embargoes[#{index}][download]", "true",
                                        embargo&.download,
                                        class: 'form-check-input')
    html <<               "Downloads"
    html <<             '</label>'
    html <<           '</div>'
    html <<           '<div class="form-check">'
    html <<             '<label>'
    html <<               check_box_tag("embargoes[#{index}][full_access]", "true",
                                        embargo&.full_access,
                                        class: 'form-check-input')
    html <<               "All Access"
    html <<             '</label>'
    html <<           '</div>'
    html <<         '</div>'
    html <<       '</div>'
    html <<       '<div class="col-sm-8">'
    html <<         '<div class="form-group">'
    html <<           'Excepted User Groups'
    if embargo && embargo.user_groups.any?
      embargo.user_groups.each_with_index do |group, index|
        html << embargo_user_group_row(group: group, index: index)
      end
    else
      html << embargo_user_group_row
    end
    html <<           '<button class="btn btn-success btn-sm add-user-group" type="button">'
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
                         options_for_select(UserGroup.all.map{ |g| [g.name, g.id] }, group&.id),
                         class: "custom-select")
    html <<   '<button class="btn btn-danger btn-sm ml-2 remove-user-group" type="button">'
    html <<     '<i class="fa fa-minus"></i>'
    html <<   '</button>'
    html << '</div>'
    raw(html.string)
  end

end