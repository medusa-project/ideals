# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :ensure_logged_in
  before_action :set_user, except: :index
  before_action :authorize_user, except: :index
  before_action :store_location, only: [:index, :show]

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
    @permitted_params = params.permit(Search::RESULTS_PARAMS +
                                        Search::SIMPLE_SEARCH_PARAMS +
                                        [:class])
    @start            = @permitted_params[:start].to_i
    @window           = window_size
    q                 = "%#{@permitted_params[:q]}%"
    @users            = User.where("LOWER(name) LIKE ? OR LOWER(uid) LIKE ?", q, q).
        where(org_dn: current_institution.org_dn).
        where("type LIKE ?", "%#{@permitted_params[:class]}").
        order(:name)
    @count            = @users.count
    @users            = @users.limit(@window).offset(@start)
    @current_page     = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
    @new_invitee      = Invitee.new
  end

  ##
  # Responds to `GET /users/:id`
  #
  def show
    set_submitted_items_ivars
    @submitted_items_count         = @count
    set_submittable_collections_ivars
    @submittable_collections_count = @count
    set_submissions_in_progress_ivars
    @submissions_in_progress_count = @count
    @count                         = nil # prevent confusion
  end

  ##
  # Responds to `GET /users/:id/properties` (XHR only)
  #
  def show_properties
    render partial: "show_properties_tab"
  end

  ##
  # Responds to `GET /users/:id/submittable-collections` (XHR only)
  #
  def show_submittable_collections
    set_submittable_collections_ivars
    render partial: "show_submittable_collections_tab"
  end

  ##
  # Responds to `GET /users/:id/submitted-items` (XHR only)
  #
  def show_submitted_items
    set_submitted_items_ivars
    render partial: "show_submitted_items_tab"
  end

  ##
  # Responds to `GET /users/:id/submissions-in-progress` (XHR only)
  #
  def show_submissions_in_progress
    set_submissions_in_progress_ivars
    render partial: "show_submissions_in_progress_tab"
  end

  ##
  # Renders results within the submitted items tab in show-user view.
  #
  # Responds to `GET /users/:id/submitted-item-results`
  #
  def submitted_item_results
    set_submitted_items_ivars
    render partial: "items/listing"
  end

  ##
  # Responds to `PATCH/PUT /users/:id/update-properties`
  #
  def update_properties
    begin
      @user.update!(properties_params)
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @user.errors.any? ? @user : e },
             status: :bad_request
    else
      flash['success'] = "Properties of user #{@user.name} have been updated."
      render "shared/reload"
    end
  end


  private

  def set_submissions_in_progress_ivars
    @submissions_in_progress = @user.submitted_items.
      where(stage: Item::Stages::SUBMITTING).
      order(updated_at: :desc)
    @count = @submissions_in_progress.count
  end

  def set_submittable_collections_ivars
    @start                   = params[:collections_start].to_i
    @window                  = window_size
    @permitted_params        = params.permit(:collections_start, :items_start, :window)
    @submittable_collections = @user.effective_submittable_collections
    @count                   = @submittable_collections.count
    if @submittable_collections.kind_of?(ActiveRecord::Relation)
      @submittable_collections = @submittable_collections.
        offset(@start).
        limit(@window)
    end
    @current_page = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
  end

  def set_submitted_items_ivars
    @start            = params[:items_start].to_i
    @window           = window_size
    @permitted_params = params.permit(:collections_start, :items_start, :window)
    @items            = Item.search.
      institution(current_institution).
      aggregations(false).
      filter(Item::IndexFields::SUBMITTER, @user.id).
      must_not(Item::IndexFields::STAGE, Item::Stages::SUBMITTING).
      order(params[:sort] => params[:direction] == "desc" ? :desc : :asc).
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

  def set_user
    @user = User.find(params[:id] || params[:user_id])
    @breadcrumbable = @user
  end

  def authorize_user
    # N.B.: without becomes(), a separate policy class would be required.
    @user ? authorize(@user.becomes(User)) : skip_authorization
  end

  def properties_params
    params.require(:user).permit(:email, :name, :phone)
  end

end
