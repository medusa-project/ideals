class UsersController < ApplicationController
  before_action :ensure_logged_in
  before_action :set_user, only: [:show, :edit, :update]
  before_action :authorize_user, only: [:show, :edit, :update]

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
    authorize(User)
    @start = params[:start].to_i
    @window = window_size

    @users = User.all
    @count = @users.count
    @users = @users.
        order(:name).
        limit(window_size).
        offset(@start)
    @current_page = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
    @permitted_params = params.permit([])
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

  def authorize_user
    # N.B.: with becomes() here, Pundit will require separate
    # IdentityUserPolicy and ShibbolethUserPolicy classes.
    @resource ? authorize(@resource.becomes(User)) : skip_authorization
  end

  def user_params
    params.require(:user).permit(:sysadmin)
  end
end
