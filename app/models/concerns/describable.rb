##
# Concern to be included by models that can have metadata ascribed to them.
#
module Describable
  extend ActiveSupport::Concern

  included do

    ##
    # @param name [String] Name of a {RegisteredElement}.
    # @return [AscribedElement] Any element matching the given name, or `nil`
    #         if no such element exists.
    #
    def element(name)
      self.elements.find{ |e| e.name == name.to_s }
    end

    ##
    # @return [String] Value of the title [AscribedElement] in the {elements}
    #                  association, or an empty string if not found.
    #
    def title
      self.element(::Configuration.instance.title_element)&.string || ""
    end

  end

end
