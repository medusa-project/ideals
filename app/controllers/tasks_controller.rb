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
      format.js { render partial: "tasks" }
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
      format.js { render partial: "tasks" }
    end
  end

  ##
  # Responds to `GET /tasks/:id` (XHR only)
  #
  def show
    render partial: "show"
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
    @tasks = Task.all
    if institution.present?
      @tasks = @tasks.where(institution: institution)
    end
    if params[:q].present?
      @tasks = @tasks.where("LOWER(status_text) LIKE ?", "%#{params[:q].downcase}%")
    end
    if params[:status].present?
      @tasks = @tasks.where(status: params[:status])
    end
    @tasks = @tasks.order(created_at: :desc).limit(100) # TODO: pagination
  end

end