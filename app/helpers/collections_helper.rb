module CollectionsHelper

  ##
  # @param unit [Unit]                  Parent unit.
  # @param include_blank [Boolean]      Whether to include a blank entry at the
  #                                     top, typically for root units.
  # @param parent_collection [Unit]     Not part of the public contract--ignore.
  # @param options [Enumerable<String>] Not part of the public contract--ignore.
  # @param level [Integer]              Not part of the public contract--ignore.
  # @return [Enumerable<String>]        Array of options for passing to
  #                                     {options_for_select}.
  #
  def collection_tree_options(unit: nil,
                              include_blank: false,
                              parent_collection: nil,
                              options: [],
                              level: 0)
    if include_blank && level == 0
      options << [ "None (Root Level)", nil ]
    end
    collections = Collection.search.
        order(RegisteredElement.sortable_field(::Configuration.instance.elements[:title])).
        limit(999)
    if unit
      collections.primary_unit(unit)
    end
    if parent_collection
      collections.parent_collection(parent_collection)
    else
      collections.include_children(false)
    end
    collections.each do |collection|
      indent = "&nbsp;&nbsp;&nbsp;&nbsp;" * level
      arrow  = (level > 0) ? raw("&#8627; ") : ""
      options << [raw(indent + arrow + collection.title), collection.id]
      collection_tree_options(unit: unit,
                              include_blank: false,
                              parent_collection: collection,
                              options: options,
                              level: level + 1)
    end
    options
  end

end