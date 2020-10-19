# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :ensure_logged_in
  before_action :set_user, only: [:show, :edit_privileges, :edit_properties,
                                  :update_privileges, :update_properties]
  before_action :authorize_user, only: [:show, :edit_privileges,
                                        :edit_properties, :update_privileges,
                                        :update_properties]

  ##
  # Responds to `GET /users/:id/edit-privileges`
  #
  def edit_privileges
    render partial: "users/privileges_form",
           locals: { user: @user }
  end

  ##
  # Responds to `GET /users/:id/edit-properties`
  #
  def edit_properties
    render partial: "users/properties_form",
           locals: { user: @user }
  end

  ##
  # Responds to `GET /users`
  #
  def index
    authorize(User)
    @start  = params[:start].to_i
    @window = window_size
    q = "%#{params[:q]}%"
    @users  = User.where("name LIKE ? OR uid LIKE ?", q, q).
        where("type LIKE ?", "%#{params[:class]}").
        order(:name)
    @count            = @users.count
    @users            = @users.limit(@window).offset(@start)
    @current_page     = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
    @permitted_params = results_params
    @new_invitee      = Invitee.new
  end

  ##
  # Responds to `GET /users/:id`
  #
  def show
    @window           = window_size
    @permitted_params = params.permit(:collections_start, :items_start, :window)

    # Submittable Collections tab content
    @collections_start        = params[:collections_start].to_i
    @submittable_collections  = @user.effective_submittable_collections
    @collections_count        = @submittable_collections.count
    @submittable_collections  = @submittable_collections.
        offset(@collections_start).
        limit(@window)
    @current_collections_page = ((@collections_start / @window.to_f).ceil + 1 if @window > 0) || 1

    # Submitted Items tab content
    @start = params[:items_start].to_i
    @items = Item.search.
        aggregations(false).
        filter(Item::IndexFields::SUBMITTER, @user.id).
        must_not(Item::IndexFields::STAGE, Item::Stages::SUBMITTING).
        order(params[:sort]).
        limit(@window).
        start(@start)
    @items             = policy_scope(@items, policy_scope_class: ItemPolicy::Scope)
    @count             = @items.count
    @current_page      = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
    @submissions       = @user.submitted_items.
        where(stage: Item::Stages::SUBMITTING).
        order(updated_at: :desc)
    @submissions_count = @submissions.count
  end

  ##
  # Responds to `PATCH/PUT /users/:id/update-privileges`
  #
  def update_privileges
    begin
      @user.update!(privileges_params)
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @user },
             status: :bad_request
    else
      flash['success'] = "Privileges of user #{@user.name} have been updated."
      render "shared/reload"
    end
  end

  ##
  # Responds to `PATCH/PUT /users/:id/update-properties`
  #
  def update_properties
    begin
      @user.update!(properties_params)
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @user },
             status: :bad_request
    else
      flash['success'] = "Properties of user #{@user.name} have been updated."
      render "shared/reload"
    end
  end

  private

  def set_user
    @user = User.find(params[:id] || params[:user_id])
    @breadcrumbable = @user
  end

  def authorize_user
    # N.B.: without becomes(), Pundit would require separate policy classes.
    @user ? authorize(@user.becomes(User)) : skip_authorization
  end

  def privileges_params
    params.require(:user).permit(:sysadmin, user_group_ids: [])
  end

  def properties_params
    params.require(:user).permit(:email, :name, :phone)
  end

end
