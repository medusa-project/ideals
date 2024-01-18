# frozen_string_literal: true

class TasksController < ApplicationController

  before_action :ensure_institution_host, :ensure_logged_in
  before_action :authorize_index, only: [:index, :index_all]
  before_action :set_task, only: :show
  before_action :authorize_task, only: :show
  before_action :store_location, only: [:index, :index_all]

  ##
  # Handles scoped tasks view, which renders a list of tasks scoped to the
  # current institution.
  #
  # Responds to `GET /tasks`
  #
  def index
    setup_index(current_institution)
    respond_to do |format|
      format.html
      format.js { render partial: "tasks", locals: { show_institution: false } }
    end
  end

  ##
  # Handles all-tasks view, which renders a list of tasks across all
  # institutions.
  #
  # Responds to `GET /tasks`
  #
  def index_all
    setup_index
    respond_to do |format|
      format.html
      format.js { render partial: "tasks", locals: { show_institution: true } }
    end
  end

  ##
  # Responds to `GET /tasks/:id` (XHR only)
  #
  def show
    respond_to do |format|
      format.html { render partial: "show", locals: { task: @task } }
      format.json { render "show" }
    end

  end


  private

  def authorize_index
    authorize(Task)
  end

  def authorize_task
    authorize(@task)
  end

  def set_task
    @task = Task.find(params[:id])
  end

  def setup_index(institution = nil)
    @permitted_params = params.permit(Search::RESULTS_PARAMS +
                                        Search::SIMPLE_SEARCH_PARAMS +
                                        [:institution_id, :queue, :status, :status_text])
    @start            = [@permitted_params[:start].to_i.abs, max_start].min
    @window           = window_size
    @tasks            = Task.all.order(created_at: :desc)
    if institution
      @tasks = @tasks.where(institution: institution)
    elsif @permitted_params[:institution_id].present?
      @tasks = @tasks.where(institution_id: @permitted_params[:institution_id])
    end
    if @permitted_params[:q].present?
      @tasks = @tasks.where("LOWER(status_text) LIKE ?", "%#{@permitted_params[:q]&.downcase}%")
    end
    if @permitted_params[:queue].present?
      @tasks = @tasks.where(queue: @permitted_params[:queue])
    end
    if @permitted_params[:status].present?
      @tasks = @tasks.where(status: @permitted_params[:status])
    end
    @count            = @tasks.count
    @tasks            = @tasks.limit(@window).offset(@start)
    @current_page     = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
  end

end