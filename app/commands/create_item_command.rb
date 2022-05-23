class CreateItemCommand < Command

  ##
  # @param submitter [User]
  # @param primary_collection [Collection]
  # @param stage [Integer] One of the [Item::Stages] constant values.
  # @param event_description [String]
  #
  def initialize(submitter:,
                 primary_collection: nil,
                 stage:              Item::Stages::SUBMITTING,
                 event_description:  "Item created upon initiation of the submission process.")
    @submitter          = submitter
    @primary_collection = primary_collection
    @stage              = stage
    @event_description  = event_description
  end

  ##
  # @return [Item]
  #
  def execute
    Item.transaction do
      item = Item.create!(submitter:          @submitter,
                          primary_collection: @primary_collection,
                          stage:              @stage)

      # For every element with placeholder text in the item's effective
      # submission profile, ascribe a metadata element with a value of that
      # text.
      item.effective_submission_profile.elements.
        where("LENGTH(placeholder_text) > ?", 0).each do |sp_element|
        item.elements.build(registered_element: sp_element.registered_element,
                            string:             sp_element.placeholder_text)
      end
      item.save!

      Event.create!(event_type:    Event::Type::CREATE,
                    item:          item,
                    user:          @submitter,
                    after_changes: item.as_change_hash,
                    description:   @event_description)
      item
    end
  end

end