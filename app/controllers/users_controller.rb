class UsersController < ApplicationController
  before_action :ensure_logged_in
  before_action :set_user, only: [:show, :edit, :update]

  ##
  # Responds to `GET /users/:id/edit`
  #
  def edit
    render partial: "users/form",
           locals: { user: @resource, context: :edit }
  end

  ##
  # Responds to `GET /users`
  #
  def index
    @resources = User.all.order(:name)
  end

  ##
  # Responds to `GET /users/:id`
  #
  def show
  end

  ##
  # Responds to `POST/PATCH/PUT /users/:id`
  #
  def update
    begin
      ActiveRecord::Base.transaction do
        @resource.update!(user_params)
        @resource.save!
      end
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @resource },
             status: :bad_request
    else
      flash['success'] = "User #{@resource.name} updated."
      render "shared/reload"
    end
  end

  private

  def set_user
    @resource = User.find(params[:id])
    @breadcrumbable = @resource
  end

  def user_params
    params.require(:user).permit({ role_ids: [] })
  end
end
