module ApplicationHelper

  MAX_PAGINATION_LINKS = 5

  ##
  # @param entity [Object] Any model object or class.
  # @return [String] HTML icon tag.
  #
  def icon_for(entity)
    entity = entity.kind_of?(Class) ? entity : entity.class
    case entity.to_s
    when "Collection"
      icon = "far fa-folder-open"
    when "Item"
      icon = "fa fa-cube"
    when "Unit"
      icon = "fa fa-university"
    when "User", "IdentityUser", "ShibbolethUser"
      icon = "fa fa-user"
    else
      icon = "fa fa-cube"
    end
    raw("<i class=\"#{icon}\"></i>")
  end

  ##
  # @param total_entities [Integer]
  # @param per_page [Integer]
  # @param permitted_params [ActionController::Parameters]
  # @param current_page [Integer]
  # @param max_links [Integer] Ideally an odd number.
  #
  def paginate(total_entities, per_page, current_page, permitted_params,
               max_links = MAX_PAGINATION_LINKS)
    return '' if total_entities <= per_page
    num_pages  = (total_entities / per_page.to_f).ceil
    first_page = [1, current_page - (max_links / 2.0).floor].max
    last_page  = [first_page + max_links - 1, num_pages].min
    first_page = last_page - max_links + 1 if
        last_page - first_page < max_links and num_pages > max_links
    prev_page  = [1, current_page - 1].max
    next_page  = [last_page, current_page + 1].min
    prev_start = (prev_page - 1) * per_page
    next_start = (next_page - 1) * per_page
    last_start = (num_pages - 1) * per_page
    unless permitted_params.kind_of?(ActionController::Parameters)
      permitted_params = params.permit(permitted_params)
    end
    remote = false

    first_link = link_to(permitted_params.except(:start),
                         remote: remote, class: 'page-link', 'aria-label': 'First') do
      raw('<span aria-hidden="true">First</span>')
    end
    prev_link = link_to(permitted_params.merge(start: prev_start),
                        remote: remote,
                        class: 'page-link',
                        'aria-label': 'Previous') do
      raw('<span aria-hidden="true">&laquo;</span>')
    end
    next_link = link_to(permitted_params.merge(start: next_start),
                        remote: remote,
                        class: 'page-link',
                        'aria-label': 'Next') do
      raw('<span aria-hidden="true">&raquo;</span>')
    end
    last_link = link_to(permitted_params.merge(start: last_start),
                        remote: remote,
                        class: 'page-link',
                        'aria-label': 'Last') do
      raw('<span aria-hidden="true">Last</span>')
    end

    # https://getbootstrap.com/docs/4.4/components/pagination/
    html = StringIO.new
    html << '<nav>'
    html <<   '<ul class="pagination">'
    html <<     sprintf('<li class="page-item %s">%s</li>',
                        current_page == first_page ? 'disabled' : '',
                        first_link)
    html <<     sprintf('<li class="page-item %s">%s</li>',
                        current_page == prev_page ? 'disabled' : '',
                        prev_link)

    (first_page..last_page).each do |page|
      start = (page - 1) * per_page
      page_link = link_to((start == 0) ? permitted_params.except(:start) :
                              permitted_params.merge(start: start), class: 'page-link', remote: remote) do
        raw("#{page} #{(page == current_page) ?
                           '<span class="sr-only">(current)</span>' : ''}")
      end
      html << sprintf('<li class="page-item %s">%s</li>',
                      page == current_page ? 'active' : '',
                      page_link)

    end
    html << sprintf('<li class="page-item %s">%s</li>',
                    current_page == next_page ? 'disabled' : '',
                    next_link)
    html << sprintf('<li class="page-item %s">%s</li>',
                    current_page == last_page ? 'disabled' : '',
                    last_link)
    html <<   '</ul>'
    html << '</nav>'
    raw(html.string)
  end

  ##
  # @param resources [Enumerable<Object>]
  # @return [String] HTML listing.
  #
  def resource_list(resources)
    html = StringIO.new
    resources.each do |resource|
      html << "<div class=\"media resource-list\">"
      html <<   "<div class=\"thumbnail\">"
      html <<     link_to(resource) do
                    icon_for(resource)
                  end
      html <<   "</div>"
      html <<   "<div class=\"media-body\">"
      html <<     "<h5 class=\"mt-0\">"
      html <<       link_to(resource.title, resource)
      html <<     "</h5>"
      html <<     "<br><br>"
      if resources.first.kind_of?(Unit)
        child_finder = Unit.search.
            parent_unit(resource).
            order("#{Unit::IndexFields::TITLE}.sort").
            limit(999)
        if child_finder.count > 0
          html << resource_list(child_finder.to_a)
        end
      end
      html <<   "</div>"
      html << "</div>"
    end
    raw(html.string)
  end

  ##
  # Returns the status of a search or browse action, e.g. "Showing n of n
  # items".
  #
  # @param total_num_results [Integer]
  # @param start [Integer]
  # @param num_results_shown [Integer]
  # @param noun [String] Singular noun for what we are showing, e.g. "item",
  #                      "collection", etc.
  # @return [String]
  #
  def search_status(total_num_results, start, num_results_shown, noun)
    last = [total_num_results, start + num_results_shown].min
    raw(sprintf("Showing %d&ndash;%d of %s %s",
                start + 1, last,
                number_with_delimiter(total_num_results),
                (total_num_results == 1) ? noun : noun.pluralize))
  end

end