# frozen_string_literal: true

class FacetTerm

  # @!attribute count
  #   @return [Integer]
  attr_accessor :count

  # @!attribute facet
  #   @return [Facet] The facet with which the term is associated.
  attr_accessor :facet

  # @!attribute label
  #   @return [String]
  attr_accessor :label

  # @!attribute name
  #   @return [String]
  attr_accessor :name

  def initialize(name: nil, label: nil, facet: nil, count: 0)
    @name  = name
    @label = label
    @facet = facet
    @count = count
  end

  ##
  # @param params [ActionController::Parameters]
  # @return [ActionController::Parameters] Input params
  #
  def added_to_params(params)
    params[:fq] = [] unless params[:fq].respond_to?(:each)
    params[:fq] << self.query
    params
  end

  ##
  # @return [String]
  #
  def query
    [self.facet.field, self.name].select(&:present?).join(":")
  end

  ##
  # @param params [ActionController::Parameters]
  # @return [ActionController::Parameters] Input params
  #
  def removed_from_params(params)
    if params[:fq].respond_to?(:each)
      params[:fq] = params[:fq].reject{ |t| t == self.query }
    end
    params
  end

end