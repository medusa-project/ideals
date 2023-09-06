# frozen_string_literal: true

class UpdateCollectionCommand < Command

  ##
  # @param user [User]
  # @param collection [Collection]
  # @param description [String]
  #
  def initialize(user:, collection:, description: nil)
    @user           = user
    @collection     = collection
    @before_changes = @collection.as_change_hash
    @description    = description
  end

  def execute(&block)
    yield(@unit)
    Event.create!(event_type:     Event::Type::UPDATE,
                  institution:    @collection.institution,
                  collection:     @collection,
                  user:           @user,
                  before_changes: @before_changes,
                  after_changes:  @collection.as_change_hash,
                  description:    @description)
  end

end
