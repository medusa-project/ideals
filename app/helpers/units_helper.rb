module UnitsHelper

  ##
  # @param units [Enumerable<Object>]
  # @return [String] HTML listing.
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
      html << "<br><br>"
      children = Unit.search.
          parent_unit(unit).
          order("#{Unit::IndexFields::TITLE}.sort").
          limit(999)
      if children.count > 0
        html << resource_list(children)
      end
      html <<   "</div>"
      html << "</div>"
    end
    raw(html.string)
  end

  ##
  # @param include_blank [Boolean]      Whether to include a blank entry at the
  #                                     top, typically for root units.
  # @param parent_unit [Unit]           Not part of the public contract--ignore.
  # @param options [Enumerable<String>] Not part of the public contract--ignore.
  # @param level [Integer]              Not part of the public contract--ignore.
  # @return [Enumerable<String>]        Array of options for passing to
  #                                     {options_for_select}.
  #
  def unit_tree_options(include_blank = false,
                        parent_unit = nil,
                        options = [],
                        level = 0)
    if include_blank && level == 0
      options << [ "None (Root Level)", nil ]
    end
    units = Unit.search.
        order("#{Unit::IndexFields::TITLE}.sort").
        limit(999)
    if parent_unit
      units.parent_unit(parent_unit)
    else
      units.include_children(false)
    end
    units.to_a.each do |unit|
      indent = "&nbsp;&nbsp;&nbsp;&nbsp;" * level
      arrow  = (level > 0) ? raw("&#8627; ") : ""
      options << [raw(indent + arrow + unit.title), unit.id]
      unit_tree_options(false, unit, options, level + 1)
    end
    options
  end

end