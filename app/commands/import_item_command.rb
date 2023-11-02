# frozen_string_literal: true

class ImportItemCommand < Command

  def initialize(primary_collection:)
    @primary_collection = primary_collection
  end

  ##
  # @return [Item]
  #
  def execute
    item = nil
    Item.transaction do
      item = Item.create!(primary_collection: @primary_collection,
                          institution:        @primary_collection.institution,
                          stage:              Item::Stages::APPROVED)
    end
    # Do this outside of the transaction block because some properties of the
    # instance don't get set until commit.
    Event.create!(event_type:    Event::Type::CREATE,
                  item:          item,
                  after_changes: item.as_change_hash,
                  description:   "Item imported from a SAF package.")
    item
  end

end