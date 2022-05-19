class ItemRelation < AbstractRelation

  def initialize
    super
    @must_nots << [Item::IndexFields::STAGE, Item::Stages::BURIED]
  end


  protected

  def facet_elements
    elements = [
      {
        label:         "Academic Unit",
        keyword_field: Item::IndexFields::UNIT_TITLES
      }
    ]
    elements + @metadata_profile.elements.select(&:faceted).map do |e|
      {
        label:         e.label,
        keyword_field: e.registered_element.indexed_keyword_field
      }
    end
  end

end
