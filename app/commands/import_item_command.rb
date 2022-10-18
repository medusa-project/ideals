class ImportItemCommand < Command

  def initialize(primary_collection:)
    @primary_collection = primary_collection
  end

  ##
  # @return [Item]
  #
  def execute
    Item.transaction do
      item = Item.create!(primary_collection: @primary_collection,
                          institution:        @primary_collection.institution,
                          stage:              Item::Stages::APPROVED)

      Event.create!(event_type:    Event::Type::CREATE,
                    item:          item,
                    after_changes: item.as_change_hash,
                    description:   "Item imported from a SAF package.")
      item
    end
  end

end