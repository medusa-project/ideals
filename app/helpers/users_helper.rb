# frozen_string_literal: true

module UsersHelper

  ##
  # Renders the filter form that appears above the main table in users view.
  #
  # @param show_institution [Boolean] Whether to include an institution select
  #                                   menu.
  # @return [String]
  #
  def user_filter_form(show_institution: false)
    html = StringIO.new
    html << '<div class="card mb-3">'
    html <<   '<div id="user-filter" class="card-body">'
    html <<     form_tag(request.path, method: :get, class: "form-inline") do
      form = StringIO.new
      form << '<div class="row">'
      form <<   '<div class="col">'
      form <<     label_tag("q", "Name or Email", class: "form-label")
      form <<     filter_field
      form <<   '</div>'
      if show_institution
        form << '<div class="col">'
        form <<   label_tag("institution_id", "Institution", class: "form-label")
        form <<   select_tag("institution_id",
                             options_for_select(Institution.all.order(:name).map{ |i| [i.name, i.id] }),
                             include_blank: true,
                             class: "form-select")
        form << '</div>'
      end
      form << '</div>'
      raw(form.string)
    end
    html <<   '</div>'
    html << '</div>'
    raw(html.string)
  end

end
