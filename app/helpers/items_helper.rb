module ItemsHelper

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

end