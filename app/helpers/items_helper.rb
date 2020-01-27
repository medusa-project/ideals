module ItemsHelper

  ##
  # @param container [Unit,Collection] Item container.
  # @param container_field [String] One of the {Item::IndexFields} constants,
  #                                 such as {Item::IndexFields::PRIMARY_UNIT_ID}
  #                                 or {Item::IndexFields::PRIMARY_COLLECTION_ID}.
  #
  def item_search_field(container, container_field)
    html = StringIO.new
    html << "<div class=\"float-right\">"
    html << form_tag(items_path, method: :get) do
      form = StringIO.new
      form << "<div class=\"input-group mb-4\">"

      form <<   hidden_field_tag(container_field, container.id)
      form <<   "<div class=\"input-group-prepend input-group-text\">"
      form <<     "<i class=\"fa fa-search\"></i>"
      form <<   "</div>"
      form <<   search_field_tag(:q, "",
                                 placeholder: raw("Search within this #{container.class.to_s.downcase}&hellip;"),
                                 'aria-label': 'Search',
                                 class: 'form-control')
      raw(form.string)
    end
    html <<   "</div>"
    html << "</div>"
    raw(html.string)
  end

end