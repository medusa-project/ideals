##
# Concern to be included by models that have surrogate {Handle}s: {Unit}s,
# {Collection}s, and {Item}s.
#
# A handle is assigned to all of these units upon creation and sent to the
# handle server upon transaction commit.
#
module Handled
  extend ActiveSupport::Concern

  included do
    after_commit :assign_handle, if: -> { handle.nil? && !destroyed? }

    ##
    # @return [void]
    #
    def assign_handle
      return if self.handle
      if self.kind_of?(Unit)
        self.handle = Handle.create!(unit: self)
      elsif self.kind_of?(Collection)
        self.handle = Handle.create!(collection: self)
      elsif self.kind_of?(Item)
        self.handle = Handle.create!(item: self)
      else
        raise "An unexpected class is including this concern. This is a bug."
      end
    end

  end

end
