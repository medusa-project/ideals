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
    elements = [
        {
            label: "Academic Unit",
            keyword_field: Item::IndexFields::UNIT_TITLES
        }
    ]
    elements += metadata_profile.elements.where(facetable: true).map do |e|
      {
          label: e.label,
          keyword_field: e.registered_element.indexed_keyword_field
      }
    end
    elements
  end

  private

  def metadata_profile
    profile = nil
    field = @filters.find{ |f| f[0] == Item::IndexFields::COLLECTIONS }
    if field
      profile = Collection.find(field[1])&.effective_metadata_profile
    end
    profile || MetadataProfile.default
  end

end
