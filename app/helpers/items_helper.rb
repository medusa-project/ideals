module ItemsHelper

  ##
  # Renders a list of reviewable {Item}s.
  #
  # @param items [Enumerable<Item>]
  # @return [String] HTML listing.
  # @see ApplicationHelper#resource_list
  #
  def review_list(items)
    html = form_tag(items_process_review_path, method: :post, id: "review-form") do
      form = StringIO.new
      form << hidden_field_tag("verb", ""); # value set to approve or reject by JS
      items.each do |item|
        form << "<div class=\"media resource-list mb-3\">"
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
        form <<     "Submitted by "
        form <<     link_to(item.submitter.becomes(User)) do
          icon_for(item.submitter) + " " + item.submitter.name
        end
        form <<     " on "
        form <<     item.created_at.strftime("%B %d, %Y")
        form <<   "</div>"
        form << "</div>"
      end
      raw(form.string)
    end
    raw(html)
  end

end