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
    @start  = results_params[:start].to_i
    @window = window_size
    @users  = User.search.
        aggregations(false).
        query_all(results_params[:q]).
        filter(User::IndexFields::CLASS,
               results_params[:class].present? ? results_params[:class] : nil).
        order(User::IndexFields::USERNAME).
        limit(@window).
        start(@start)
    @count            = @users.count
    @current_page     = @users.page
    @permitted_params = results_params
  end

  ##
  # Responds to `GET /users/:id`
  #
  def show
    @start = params[:start].to_i
    @window = window_size
    @items = Item.search.
        aggregations(false).
        filter(Item::IndexFields::SUBMITTER, @resource.id).
        order(RegisteredElement.sortable_field(::Configuration.instance.elements[:title])).
        limit(@window).
        start(@start)
    @item_count = @items.count
    @current_page = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
    @results_params = params.permit(:start, :window)
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

  def results_params
    params.permit(:class, :q, :start, :window)
  end

  def user_params
    params.require(:user).permit(:sysadmin)
  end
end
