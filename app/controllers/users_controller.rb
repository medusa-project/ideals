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
    @new_invitee      = Invitee.new
  end

  ##
  # Responds to `GET /users/:id`
  #
  def show
    @start  = params[:start].to_i
    @window = window_size
    @items  = Item.search.
        aggregations(false).
        filter(Item::IndexFields::SUBMITTER, @user.id).
        filter(Item::IndexFields::SUBMITTING, false).
        order(params[:sort]).
        limit(@window).
        start(@start)
    @items            = policy_scope(@items, policy_scope_class: ItemPolicy::Scope)
    @count            = @items.count
    @current_page     = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
    @permitted_params = params.permit(:start, :window)
    @submissions      = @user.submitted_items.
        where(submitting: true).
        order(updated_at: :desc)
  end

  ##
  # Responds to `PATCH/POST /users/:id`
  #
  def update_privileges
    begin
      ActiveRecord::Base.transaction do
        @user.update!(privileges_params)
      end
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
  # Responds to `PATCH/POST /users/:id`
  #
  def update_properties
    begin
      ActiveRecord::Base.transaction do
        @user.update!(properties_params)
      end
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

  def results_params
    params.permit(:class, :q, :start, :window)
  end

  def privileges_params
    params.require(:user).permit(:sysadmin, user_group_ids: [])
  end

  def properties_params
    params.require(:user).permit(:email, :name, :phone)
  end
end
