class CreateItemCommand < Command

  ##
  # @param submitter [User]
  # @param institution [Institution]
  # @param primary_collection [Collection]
  # @param stage [Integer] One of the [Item::Stages] constant values.
  # @param event_description [String]
  #
  def initialize(submitter:,
                 institution:,
                 primary_collection: nil,
                 stage:              Item::Stages::SUBMITTING,
                 event_description:  "Item created upon initiation of the submission process.")
    @submitter          = submitter
    @institution        = institution
    @primary_collection = primary_collection
    @stage              = stage
    @event_description  = event_description
  end

  ##
  # @return [Item]
  #
  def execute
    item = nil
    Item.transaction do
      item = Item.create!(submitter:          @submitter,
                          institution:        @institution,
                          primary_collection: @primary_collection,
                          stage:              @stage,
                          deposit_agreement:  @institution.deposit_agreement)

      # For every element with placeholder text in the item's effective
      # submission profile, ascribe a metadata element with a value of that
      # text.
      if item.effective_submission_profile
        item.effective_submission_profile.elements.
          where("LENGTH(placeholder_text) > ?", 0).each do |sp_element|
          item.elements.build(registered_element: sp_element.registered_element,
                              string:             sp_element.placeholder_text)
        end
      end
      item.save!
    end
    # Do this outside of the transaction block because some properties of the
    # instance don't get set until commit.
    Event.create!(event_type:    Event::Type::CREATE,
                  item:          item,
                  user:          @submitter,
                  after_changes: item.as_change_hash,
                  description:   @event_description)
    item
  end

end