module UnitsHelper

  ##
  # @param selected_unit [Unit]         Optional unit to mark as selected.
  # @param parent_unit [Unit]           Not part of the public contract--ignore.
  # @param options [Enumerable<String>] Not part of the public contract--ignore.
  # @param level [Integer]              Not part of the public contract--ignore.
  # @return [ActiveSupport::SafeBuffer,Enumerable<String>] Return value of
  #         {options_for_select}.
  #
  def unit_tree_options_for_select(selected_unit = nil,
                                   parent_unit = nil,
                                   options = [],
                                   level = 0)
    sort_field = "#{Unit::IndexFields::TITLE}.sort"
    units = Unit.search.
        order(sort_field).
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
      unit_tree_options_for_select(selected_unit, unit, options, level + 1)
    end
    options_for_select(options, selected_unit&.id)
  end

end