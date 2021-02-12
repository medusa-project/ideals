class CreateItemCommand < Command

  def initialize(submitter:, primary_collection: nil)
    @submitter          = submitter
    @primary_collection = primary_collection
  end

  ##
  # @return [Item]
  #
  def execute
    Item.transaction do
      item = Item.create!(submitter:          @submitter,
                          primary_collection: @primary_collection,
                          stage:              Item::Stages::SUBMITTING,
                          discoverable:       false)

      # For every element with placeholder text in the item's effective
      # submission profile, ascribe a metadata element with a value of that
      # text.
      item.effective_submission_profile.elements.
        where("LENGTH(placeholder_text) > ?", 0).each do |sp_element|
        item.elements.build(registered_element: sp_element.registered_element,
                            string:             sp_element.placeholder_text).save!
      end

      Event.create!(event_type:    Event::Type::CREATE,
                    item:          item,
                    user:          @submitter,
                    after_changes: item,
                    description:   "Item created upon initiation of the submission process.")
      item
    end
  end

end