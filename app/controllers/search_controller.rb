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
                                        Search::RESULTS_PARAMS +
                                        [:item_type])
    @start            = [@permitted_params[:start].to_i.abs, max_start].min
    @window           = window_size
    @items            = EntityRelation.new.
      aggregations(true).
      facet_filters(@permitted_params[:fq]).
      start(@start).
      limit(@window)
    if institution_host?
      @items.institution(current_institution)
      if policy(Item).show_private?
        case params[:item_type]
        when "private"
          @items.
            filter_range("#{Item::IndexFields::EMBARGOES}.#{Embargo::IndexFields::ALL_ACCESS_EXPIRES_AT}",
                         :gt,
                         Time.now.strftime("%Y-%m-%d")).
            must_not(Item::IndexFields::STAGE, Item::Stages::WITHDRAWN)
        when "rejected"
          @items.filter(Item::IndexFields::STAGE, Item::Stages::REJECTED)
        when "withdrawn"
          @items.filter(Item::IndexFields::STAGE, Item::Stages::WITHDRAWN)
        when "deleted"
          @items.include_buried.
            filter(Item::IndexFields::STAGE, Item::Stages::BURIED)
        end
      else
        @items = policy_scope(@items, policy_scope_class: ItemPolicy::Scope)
      end
    else
      @items.metadata_profile(MetadataProfile.global)
    end
    if @permitted_params[:sort].present?
      @items.order(@permitted_params[:sort] =>
                     (@permitted_params[:direction] == "desc") ? :desc : :asc)
    end
    process_search_query(@items)

    @count        = @items.count
    @facets       = @items.facets
    @current_page = @items.page
  end

end