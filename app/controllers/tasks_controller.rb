class TasksController < ApplicationController

  before_action :ensure_logged_in
  before_action :authorize_index, only: :index
  before_action :set_task, only: :show
  before_action :authorize_task, only: :show

  ##
  # Responds to `GET /tasks`
  #
  def index
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