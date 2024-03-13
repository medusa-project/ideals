# frozen_string_literal: true

##
# Relation for cross-entity search.
#
class EntityRelation < AbstractRelation

  def initialize
    super
    @must_nots << [Unit::IndexFields::BURIED, true]
    @must_nots << [Collection::IndexFields::BURIED, true]
    @must_nots << [Item::IndexFields::STAGE, Item::Stages::BURIED]
  end

  ##
  # Buried items are excluded from results by default--this method removes that
  # exclusion.
  #
  # @return [self]
  #
  def include_buried
    @must_nots.delete([Unit::IndexFields::BURIED, true])
    @must_nots.delete([Collection::IndexFields::BURIED, true])
    @must_nots.delete([Item::IndexFields::STAGE, Item::Stages::BURIED])
    self
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
    elements = []
    if @institution
      elements << {
        label:         "Academic Unit",
        keyword_field: Item::IndexFields::UNIT_TITLES
      }
    else # we are in global scope
      elements << {
        label:         "Institution",
        keyword_field: Item::IndexFields::INSTITUTION_NAME
      }
    end
    elements + @metadata_profile.elements.select(&:faceted).map do |e|
      {
        label:         e.label,
        keyword_field: e.registered_element.indexed_keyword_field
      }
    end
  end

end
