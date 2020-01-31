module UnitsHelper

  ##
  # @param units [Enumerable<Unit>]
  # @return [String] HTML unit list.
  #
  def unit_list(units)
    html = StringIO.new
    units.each do |unit|
      html << "<div class=\"media resource-list\">"
      html <<   "<div class=\"thumbnail\">"
      html <<     link_to(unit) do
                    icon_for(unit)
                  end
      html <<   "</div>"
      html <<   "<div class=\"media-body\">"
      html <<     "<h5 class=\"mt-0\">"
      html <<       link_to(unit.title, unit)
      html <<     "</h5>"
      html <<     "<br><br>"

      child_finder = Unit.search.
          parent_unit(unit).
          order("#{Unit::IndexFields::TITLE}.sort").
          limit(999)
      if child_finder.count > 0
        html << unit_list(child_finder.to_a)
      end
      html <<   "</div>"
      html << "</div>"
    end
    raw(html.string)
  end

end