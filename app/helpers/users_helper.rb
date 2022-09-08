module UsersHelper

  ##
  # Renders the filter form that appears above the main table in users view.
  #
  # @return [String]
  #
  def user_filter_form
    html = StringIO.new
    html << '<div class="card mb-3">'
    html <<   '<div class="card-body">'
    html <<     form_tag(users_path, method: :get, class: "form-inline") do
      form = StringIO.new
      form << label_tag(nil, "Name or Email", class: "mr-1")
      form << filter_field

      form << label_tag(nil, "Authentication Type", class: "ml-3 mr-1")
      form << select_tag("class", options_for_select([["Any", ""],
                                                      ["Shiboleth", ShibbolethUser.to_s],
                                                      ["Local", LocalUser.to_s]]),
                         class: "custom-select")

      form << '<div class="btn-group">'
      form <<   button_tag("Clear", type: "reset", class: "btn btn-outline-secondary ml-3")
      form <<   submit_tag("Filter", name: "", class: "btn btn-primary")
      form << '</div>'
      raw(form.string)
    end
    html <<   '</div>'
    html << '</div>'
    raw(html.string)
  end

end
