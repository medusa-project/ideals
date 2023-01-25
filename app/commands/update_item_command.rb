##
# Contrary to its name, this class doesn't actually directly update an [Item].
# Instead, {execute} executes a block which contains item-updating code.
# This enables complex and multi-step updates while still building a correct
# [Event].
#
class UpdateItemCommand < Command

  ##
  # @param item [Item]
  # @param user [User]
  # @param description [String]
  # @param before_changes [Hash] If not provided, the item's current
  #                              {as_change_hash change hash} is used.
  #
  def initialize(item:, user:, description: nil, before_changes: nil)
    @item           = item
    @user           = user
    @description    = description
    @before_changes = before_changes || @item.as_change_hash
  end

  ##
  # @return [void]
  #
  def execute(&block)
    Item.transaction do
      yield(@item)
      @item.reload
      Event.create!(event_type:     Event::Type::UPDATE,
                    item:           @item,
                    user:           @user,
                    before_changes: @before_changes,
                    after_changes:  @item.as_change_hash,
                    description:    @description)
    end
  end

end