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
      if unit.units.count > 0 || unit.unit_collection_memberships.where(unit_default: false).count > 0
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
  # Renders a list of all units of which a given user is an effective
  # administrator in a series of `option` elements. To render the whole tree
  # instead, use {unit_tree_options}.
  #
  # @param user [User]                  All units of which this user is an
  #                                     effective administrator will be
  #                                     included in the list.
  # @param include_blank [Boolean]      Whether to include a blank entry at the
  #                                     top.
  # @param exclude_unit [Unit]          Unit to exclude from the list.
  # @return [Enumerable<String>]        Array of options for passing to
  #                                     {options_for_select}.
  #
  def unit_list_options(user:,
                        include_blank: false,
                        exclude_unit:  nil)
    options  = []
    options << [nil, nil] if include_blank
    units = Unit.all.
      order(:title).
      reject{ |u| u == exclude_unit }.
      select{ |u| user.effective_unit_admin?(u) }
    options += units.map{ |u| [u.title, u.id] }
    options
  end

  ##
  # Renders a unit tree in a series of `option` elements. Use this to include
  # the full unit tree in a select menu. To include only particular units, use
  # {unit_list_options}.
  #
  # @param include_blank [Boolean]      Whether to include a blank entry at the
  #                                     top.
  # @param include_root [Boolean]       Whether to include a root entry at the
  #                                     top.
  # @param include_only_admin [Boolean] Whether to include only units of which
  #                                     the {ApplicationController#current_user
  #                                     current user} is an effective
  #                                     administrator.
  # @param exclude_unit [Unit]          Unit to exclude from the list.
  # @param parent_unit [Unit]           Not part of the public contract--ignore.
  # @param options [Enumerable<String>] Not part of the public contract--ignore.
  # @param level [Integer]              Not part of the public contract--ignore.
  # @return [Enumerable<String>]        Array of options for passing to
  #                                     {options_for_select}.
  #
  def unit_tree_options(include_blank: false,
                        include_root: false,
                        include_only_admin: false,
                        exclude_unit: nil,
                        parent_unit: nil,
                        options: [],
                        level: 0)
    if include_blank && level == 0
      options << [nil, nil]
    end
    if include_root && level == 0
      options << ["None (Root Level)", nil]
    end
    units = Unit.search.
        institution(current_institution).
        order("#{Unit::IndexFields::TITLE}.sort").
        limit(999)
    if parent_unit
      units.parent_unit(parent_unit)
    else
      units.include_children(false)
    end
    if include_only_admin && current_user
      units = units.select{ |u| current_user.effective_unit_admin?(u) }
    end
    units.reject{ |u| u == exclude_unit }.each do |unit|
      indent   = "&nbsp;&nbsp;&nbsp;&nbsp;" * level
      arrow    = (level > 0) ? raw("&#8627; ") : ""
      options << [raw(indent + arrow + unit.title), unit.id]
      unit_tree_options(include_blank: include_blank,
                        include_root:  false,
                        parent_unit:   unit,
                        options:       options,
                        level:         level + 1)
    end
    options
  end

end