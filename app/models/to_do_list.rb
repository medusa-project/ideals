##
# Supports a simple to-do list. For example:
#
# * "Complete 5 submissions"
# * "Approve 3 users"
#
# (Total number of items: 8)
#
class ToDoList

  attr_accessor :total_items

  # @return [Enumerable<Hash>] With `:message` and `:url` keys.
  attr_accessor :items

  def initialize
    @items       = []
    @total_items = 0
  end

end