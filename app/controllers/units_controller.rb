# frozen_string_literal: true

class UnitsController < ApplicationController
  before_action :ensure_logged_in, except: [:children, :index, :show]
  before_action :set_unit, only: [:children, :edit_access, :edit_membership,
                                  :edit_properties, :show, :update, :destroy]
  before_action :authorize_unit, only: [:children, :edit_access,
                                        :edit_membership, :edit_properties,
                                        :show, :update, :destroy]

  ##
  # Renders a partial for the expandable unit list used in {index}. Has the
  # same permissions as {show}.
  #
  # Responds to `GET /units/:unit_id/children` (XHR only)
  #
  def children
    raise ActionController::BadRequest if params[:unit_id].blank?
    @units = Unit.search.
        filter(Unit::IndexFields::PARENT, params[:unit_id].to_i).
        include_children(true).
        order("#{Unit::IndexFields::TITLE}.sort").
        limit(999)
    render partial: "children"
  end

  ##
  # Responds to `POST /units`
  #
  def create
    @resource = Unit.new(unit_params)
    authorize @resource
    begin
      ActiveRecord::Base.transaction do
        @resource.save!
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @resource.errors.any? ? @resource : e },
             status: :bad_request
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Unit \"#{@resource.title}\" created."
      render "create", locals: { unit: @resource }
    end
  end

  ##
  # Responds to `DELETE /units/:id`
  #
  def destroy
    begin
      ActiveRecord::Base.transaction do
        @resource.destroy!
      end
    rescue => e
      flash['error'] = "#{e}"
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Unit \"#{@resource.title}\" deleted."
    ensure
      redirect_to units_path
    end
  end

  ##
  # Used for editing access control.
  #
  # Responds to `GET /units/:id/edit-membership` (XHR only)
  #
  def edit_access
    render partial: "units/access_form",
           locals: { unit: @resource }
  end

  ##
  # Used for editing unit membership.
  #
  # Responds to `GET /units/:id/edit-membership` (XHR only)
  #
  def edit_membership
    render partial: "units/membership_form",
           locals: { unit: @resource }
  end

  ##
  # Used for editing basic properties.
  #
  # Responds to GET `/units/:id/edit` (XHR only)
  #
  def edit_properties
    render partial: "units/properties_form",
           locals: { unit: @resource }
  end

  ##
  # Responds to `GET /units`
  #
  def index
    @units = Unit.search.
        include_children(false).
        order("#{Unit::IndexFields::TITLE}.sort").
        limit(9999)
    @new_unit = Unit.new
  end

  ##
  # Responds to GET /units/:id
  #
  def show
    @new_unit = Unit.new
    # Subunits tab
    @subunits = Unit.search.
        parent_unit(@resource).
        order("#{Unit::IndexFields::TITLE}.sort").
        limit(999).
        to_a
    # Collections tab
    @collections = Collection.search.
        filter(Collection::IndexFields::PRIMARY_UNIT, @resource.id).
        order(RegisteredElement.sortable_field(::Configuration.instance.elements[:title])).
        limit(999).
        to_a
    # Items tab
    @start = params[:start].to_i
    @window = window_size
    @items = Item.search.
        query_all(params[:q]).
        filter(Item::IndexFields::UNITS, params[:id]).
        order(params[:sort]).
        start(@start).
        limit(@window)
    @items            = policy_scope(@items, policy_scope_class: ItemPolicy::Scope)
    @count            = @items.count
    @current_page     = @items.page
    @permitted_params = results_params
  end

  ##
  # Responds to `PATCH/PUT /units/:id`
  #
  def update
    begin
      ActiveRecord::Base.transaction do
        @resource.update!(unit_params)
        assign_administrators
        @resource.save!
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @resource.errors.any? ? @resource : e },
             status: :bad_request
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Unit \"#{@resource.title}\" updated."
      render 'shared/reload'
    end
  end

  private

  def set_unit
    @resource = Unit.find(params[:id] || params[:unit_id])
    @breadcrumbable = @resource
  end

  def authorize_unit
    @resource ? authorize(@resource) : skip_authorization
  end

  def assign_administrators
    # Non-primary administrators
    if params[:administering_users]
      @resource.administrators.where(primary: false).destroy_all
      params[:administering_users].select(&:present?).each do |user_str|
        user = User.from_autocomplete_string(user_str)
        @resource.errors.add(:administrators,
                             "includes a user that does not exist") unless user
        @resource.administering_users << user
      end
    end
    # Primary administrator
    if params[:primary_administrator]
      @resource.primary_administrator =
          User.from_autocomplete_string(params[:primary_administrator])
    end
  end

  def unit_params
    params.require(:unit).permit(:title, :parent_id)
  end
end
