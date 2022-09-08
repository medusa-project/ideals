class ItemRelation < AbstractRelation

  def initialize
    super
    @must_nots << [Item::IndexFields::STAGE, Item::Stages::BURIED]
  end

  ##
  # Filters out items with current all-access embargoes.
  #
  # @return [self]
  #
  def non_embargoed
    must_not_range("#{Item::IndexFields::EMBARGOES}.#{Embargo::IndexFields::ALL_ACCESS_EXPIRES_AT}",
                   :gt,
                   Time.now.strftime("%Y-%m-%d"))
    self
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
