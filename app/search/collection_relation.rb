class CollectionRelation < AbstractRelation

  protected

  def facet_elements
    elements = [
        {
            label: "Academic Unit",
            keyword_field: "#{Collection::IndexFields::UNIT_TITLES}.keyword"
        }
    ]
    elements += MetadataProfile.default.facetable_elements.map do |e|
      {
          label: e.label,
          keyword_field: e.registered_element.indexed_keyword_field
      }
    end
    elements
  end

end