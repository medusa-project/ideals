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
    @limit = 100
    @tasks = Task.
      where(institution: current_institution).
      order(created_at: :desc).
      limit(@limit)
    respond_to do |format|
      format.js
      format.html
    end
  end

  ##
  # Handles all-tasks view, which renders a list of tasks across all
  # institutions.
  #
  # Responds to `GET /tasks`
  #
  def index_all
    @tasks = Task.all.order(created_at: :desc).limit(100)
    respond_to do |format|
      format.js
      format.html
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

end