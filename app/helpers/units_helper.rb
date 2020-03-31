module UnitsHelper

  ##
  # Renders a list of units. Works in conjunction with the
  # `IDEALS.ExpandableResourceList` JavaScript function.
  #
  # @param units [Enumerable<Unit>]
  # @return [String] HTML list.
  #
  def expandable_unit_list(units)
    html = StringIO.new
    html << "<ul>"
    units.each do |unit|
      html << "<li data-id=\"#{unit.id}\">"
      if unit.all_children.length > 0 || unit.all_collections.reject(&:unit_default).length > 0
        html <<   "<button class=\"btn btn-link expand\" type=\"button\" data-class=\"#{unit.class}\">"
        html <<     "<i class=\"far fa-plus-square\"></i>"
        html <<   "</button>"
      end
      html <<   link_to(unit) do
        raw("#{icon_for(unit)} #{unit.title}")
      end
      # sub-units inserted here via JS
      html << "</li>"
    end
    html << "</ul>"
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