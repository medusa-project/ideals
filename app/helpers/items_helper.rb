module ItemsHelper

  ##
  # @param container [Unit,Collection] Item container.
  # @param container_field [String] One of the {Item::IndexFields} constants,
  #                                 such as {Item::IndexFields::PRIMARY_UNIT_ID}
  #                                 or {Item::IndexFields::PRIMARY_COLLECTION_ID}.
  #
  def item_search_field(container = nil, container_field = nil)
    html = form_tag(items_path, method: :get, class: "filter") do
      form = StringIO.new
      form << "<div class=\"input-group mb-4 filter-field\">"
      form <<   hidden_field_tag(container_field, container.id) if container
      form <<   "<div class=\"input-group-prepend input-group-text\">"
      form <<     "<i class=\"fa fa-filter\"></i>"
      form <<   "</div>"
      placeholder = container ?
                        "Search within this #{container.class.to_s.downcase}&hellip;" :
                        ""
      form <<   search_field_tag(:q, "",
                                 placeholder: raw(placeholder),
                                 'aria-label': 'Search',
                                 class: 'form-control')
      form <<   "<div class=\"input-group-append\">"
      form <<     submit_tag(container ? "Search" : "Filter",
                             name: "",
                             class: "btn btn-outline-secondary")
      form <<   "</div>"
      form << "</div>"
      raw(form.string)
    end
    raw(html)
  end

end