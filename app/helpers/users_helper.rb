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
    html <<     form_tag(request.fullpath, method: :get, class: "form-inline") do
      form = StringIO.new
      form << label_tag("q", "Name or Email", class: "mr-1")
      form << filter_field
      if show_institution
        form << label_tag("institution_id", "Institution", class: "ml-3 mr-1")
        form << select_tag("institution_id", options_for_select(Institution.all.order(:name).map{ |i| [i.name, i.id] }),
                           include_blank: true,
                           class: "custom-select")
      end
      form << label_tag("class", "Authentication Type", class: "ml-3 mr-1")
      form << select_tag("class", options_for_select([["Any", ""],
                                                      ["Shiboleth", ShibbolethUser.to_s],
                                                      ["Local", LocalUser.to_s]]),
                         class: "custom-select")
      raw(form.string)
    end
    html <<   '</div>'
    html << '</div>'
    raw(html.string)
  end

end
