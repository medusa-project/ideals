##
# Concern to be included by models that can have metadata ascribed to them.
#
module Describable
  extend ActiveSupport::Concern

  included do

    ##
    # @return [String] Value of the title [AscribedElement] in the {elements}
    #                  association, or an empty string if not found.
    #
    def title
      config = ::Configuration.instance
      self.elements.find{ |e| e.name == config.title_element }&.string || ""
    end

  end

end
