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
      child_finder = Unit.search.
          parent_unit(unit).
          order("#{Unit::IndexFields::TITLE}.sort").
          limit(999)
      if child_finder.count > 0
        html << resource_list(child_finder.to_a)
      end
      html <<   "</div>"
      html << "</div>"
    end
    raw(html.string)
  end

  ##
  # @param selected_unit_ids [Enumerable<Integer>] IDs of units to check.
  # @param parent_unit [Unit] Not part of the public contract--ignore.
  # @param io [StringIO]      Not part of the public contract--ignore.
  # @param level [Integer]    Not part of the public contract--ignore.
  # @return [String] HTML checkboxes.
  #
  def unit_tree_checkboxes(selected_unit_ids = [],
                           parent_unit = nil,
                           io = StringIO.new,
                           level = 0)
    if level == 0
      # Ensures that an empty array is sent when no boxes are checked.
      io << hidden_field_tag("collection[unit_ids][]")
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
      io << "<div class=\"form-check\">"
      io << check_box_tag("collection[unit_ids][]", unit.id,
                          selected_unit_ids.include?(unit.id),
                          { id: "collection_unit_#{unit.id}",
                            class: "form-check-input" })
      io << label_tag("collection_unit_#{unit.id}",
                      raw(indent + arrow + unit.title),
                      class: "form-check-label")
      io << "</div>"
      unit_tree_checkboxes(selected_unit_ids, unit, io, level + 1)
    end
    raw(io.string)
  end

  ##
  # @param selected_unit [Unit]         Optional unit to mark as selected.
  # @param include_blank [Boolean]      Whether to include a blank entry at the
  #                                     top, typically for root units.
  # @param parent_unit [Unit]           Not part of the public contract--ignore.
  # @param options [Enumerable<String>] Not part of the public contract--ignore.
  # @param level [Integer]              Not part of the public contract--ignore.
  # @return [ActiveSupport::SafeBuffer,Enumerable<String>] Return value of
  #         {options_for_select}.
  #
  def unit_tree_options_for_select(selected_unit = nil,
                                   include_blank = false,
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
      unit_tree_options_for_select(selected_unit, false, unit, options, level + 1)
    end
    options_for_select(options, selected_unit&.id)
  end

end