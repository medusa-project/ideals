##
# Contrary to its name, this class doesn't actually directly update an {Item}.
# Instead, {execute} executes a block which contains item-updating code.
# This enables complex and multi-step updates while still building a correct
# {Event}.
#
class UpdateItemCommand < Command

  def initialize(item:, user:, description: nil)
    @item        = item
    @user        = user
    @description = description
  end

  ##
  # @return [void]
  #
  def execute(&block)
    Item.transaction do
      before_changes = @item.as_change_hash
      yield(@item)
      Event.create!(event_type:     Event::Type::UPDATE,
                    item:           @item,
                    user:           @user,
                    before_changes: before_changes,
                    after_changes:  @item.as_change_hash,
                    description:    @description)
    end
  end

end