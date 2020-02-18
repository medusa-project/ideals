class ItemRelation < AbstractRelation

  def initialize
    super
    # Initialize filters to include only publicly accessible items by
    # default. Clients may override where necessary.
    filter(Item::IndexFields::DISCOVERABLE, true)
    filter(Item::IndexFields::IN_ARCHIVE, true)
    filter(Item::IndexFields::WITHDRAWN, false)
  end

  protected

  def facet_elements
    profile = nil
    field = @filters.find{ |f| f[0] == Item::IndexFields::COLLECTIONS }
    if field
      profile = Collection.find(field[1])&.effective_metadata_profile
    end
    profile ||=  MetadataProfile.default
    profile.elements.where(facetable: true).map do |e|
      {
          label: e.registered_element.label,
          keyword_field: e.registered_element.indexed_keyword_field
      }
    end
  end

end
