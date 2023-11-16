# frozen_string_literal: true

class ItemRelation < AbstractRelation

  def initialize
    super
    @must_nots << [Item::IndexFields::STAGE, Item::Stages::BURIED]
  end

  ##
  # Buried items are excluded from results by default--this method removes that
  # exclusion.
  #
  # @return [self]
  #
  def include_buried
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

end
