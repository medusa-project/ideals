class CreateCollectionCommand < Command

  ##
  # @param user [User]             User performing the command.
  # @param collection [Collection] New instance, already initialized and ready
  #                                to save.
  #
  def initialize(user:, collection:)
    @user       = user
    @collection = collection
  end

  def execute
    Collection.transaction do
      @collection.save!
      Event.create!(event_type:    Event::Type::CREATE,
                    institution:   @collection.institution,
                    collection:    @collection,
                    user:          @user,
                    after_changes: @collection.as_change_hash)
    end
  end

end