# frozen_string_literal: true

class EventsController < ApplicationController

  before_action :ensure_institution_host, :ensure_logged_in
  before_action :authorize_index, only: [:index, :index_all]
  before_action :set_event, only: :show
  before_action :authorize_event, only: :show
  before_action :store_location, only: [:index, :index_all]

  ##
  # Handles scoped events view, which renders a list of events scoped to the
  # current institution.
  #
  # Responds to `GET /events`
  #
  def index
    setup_index(current_institution)
    respond_to do |format|
      format.html
      format.js { render partial: "events" }
    end
  end

  ##
  # Handles all-events view, which renders a list of events across all
  # institutions.
  #
  # Responds to `GET /events`
  #
  def index_all
    setup_index
    respond_to do |format|
      format.html
      format.js { render partial: "events" }
    end
  end

  ##
  # Responds to `GET /events/:id` (XHR only)
  #
  def show
    render plain: "Not Implemented"
    #render partial: "show"
  end


  private

  def authorize_index
    authorize(Event)
  end

  def authorize_event
    authorize(@event)
  end

  def set_event
    @event = Event.find(params[:id])
  end

  def setup_index(institution = nil)
    @permitted_params = params.permit(Search::RESULTS_PARAMS +
                                        Search::SIMPLE_SEARCH_PARAMS +
                                        [:status_text, :status])
    @start            = [@permitted_params[:start].to_i.abs, MAX_START].min
    @window           = window_size
    @events           = Event.all.order(created_at: :desc)
    if institution
      @events = @events.where(institution: institution)
    end
    if @permitted_params[:q].present?
      @events = @events.where("LOWER(description) LIKE ?",
                              "%#{@permitted_params[:q]&.downcase}%")
    end
    if @permitted_params[:status].present?
      @events = @events.where(status: @permitted_params[:status])
    end
    @count            = @events.count
    @events           = @events.limit(@window).offset(@start)
    @current_page     = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
  end

end
