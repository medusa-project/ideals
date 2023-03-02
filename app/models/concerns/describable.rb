##
# Concern to be included by models that can have metadata ascribed to them.
#
# N.B.: Because of the normalization/performance trade-off made in the database
# design, it's probably faster to avoid querying the database for elements,
# using e.g. {ApplicationRecord#where}`, and instead to use {Enumerable#select}
# against an entity's `elements` relationship. This will be more costly on the
# first query, but subsequent queries should then be much faster.
#
module Describable
  extend ActiveSupport::Concern

  included do

    ##
    # @return [Enumerable<String>] All author [AscribedElement]s in the
    #                              {elements} association.
    #
    def authors
      self.elements.select{ |e| e.name == self.institution.author_element&.name }
    end

    ##
    # @return [String] Value of any description [AscribedElement] in the
    #                  {elements} association, or an empty string if not found.
    #
    def description
      self.element(self.institution.description_element&.name)&.string || ""
    end

    ##
    # @param name [String] Name of a {RegisteredElement}.
    # @return [AscribedElement] Any element matching the given name, or `nil`
    #         if no such element exists.
    #
    def element(name)
      self.elements.find{ |e| e.name == name.to_s }
    end

    ##
    # @return [String] Value of any title {AscribedElement} in the {elements}
    #                  association, or an empty string if not found.
    #
    def title
      self.element(self.institution&.title_element&.name)&.string || ""
    end

  end

end
