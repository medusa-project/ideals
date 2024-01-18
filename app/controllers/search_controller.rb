# frozen_string_literal: true

##
# Handles cross-entity search.
#
class SearchController < ApplicationController

  include Search

  before_action :store_location

  ##
  # Responds to `GET /search`
  #
  def index
    @permitted_params = params.permit(Search::SIMPLE_SEARCH_PARAMS +
                                        Search::advanced_search_params +
                                        Search::RESULTS_PARAMS)
    @start            = [@permitted_params[:start].to_i.abs, max_start].min
    @window           = window_size
    @items            = EntityRelation.new.
      aggregations(true).
      facet_filters(@permitted_params[:fq]).
      start(@start).
      limit(@window)
    if institution_host?
      @items = @items.institution(current_institution)
    else
      @items = @items.metadata_profile(MetadataProfile.global)
    end
    if @permitted_params[:sort].present?
      @items.order(@permitted_params[:sort] =>
                     (@permitted_params[:direction] == "desc") ? :desc : :asc)
    end
    process_search_query(@items)

    @items        = policy_scope(@items, policy_scope_class: ItemPolicy::Scope)
    @count        = @items.count
    @facets       = @items.facets
    @current_page = @items.page
  end

end