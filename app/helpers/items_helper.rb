module ItemsHelper

  ##
  # @param container [Unit,Collection] Item container.
  # @param container_field [String] One of the {Item::IndexFields} constants,
  #                                 such as {Item::IndexFields::PRIMARY_UNIT_ID}
  #                                 or {Item::IndexFields::PRIMARY_COLLECTION_ID}.
  #
  def item_search_field(container = nil, container_field = nil)
    html = StringIO.new
    html << "<div class=\"input-group mb-4 filter-field\">"
    html <<   hidden_field_tag(container_field, container.id) if container
    html <<   "<div class=\"input-group-prepend input-group-text\">"
    html <<     "<i class=\"fa fa-filter\"></i>"
    html <<   "</div>"
    placeholder = container ?
                      "Search within this #{container.class.to_s.downcase}&hellip;" :
                      ""
    html <<   search_field_tag(:q, "",
                               placeholder: raw(placeholder),
                               'aria-label': 'Search',
                               class: 'form-control')
    html <<   "<div class=\"input-group-append\">"
    html <<     submit_tag(container ? "Search" : "Filter",
                           name: "",
                           class: "btn btn-outline-primary")
    html <<   "</div>"
    html << "</div>"
    raw(html.string)
  end

end