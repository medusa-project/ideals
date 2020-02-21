# frozen_string_literal: true

class UnitsController < ApplicationController
  before_action :ensure_logged_in, except: [:index, :show]
  before_action :set_unit, only: [:show, :edit, :update, :destroy]
  before_action :authorize_unit, only: [:show, :edit, :update, :destroy]

  ##
  # Responds to `POST /units`
  #
  def create
    begin
      @resource = Unit.new(unit_params)
      authorize @resource
      ActiveRecord::Base.transaction do
        @resource.save!
        assign_administrators
        @resource.save!
      end
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @resource },
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
  # Responds to `GET /units/:id/edit`
  #
  def edit
    render partial: "units/form",
           locals: { unit: @resource, context: :edit }
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
        start(@start).
        limit(@window)
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
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @resource },
             status: :bad_request
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Unit \"#{@resource.title}\" updated."
      render 'shared/reload'
    end
  end

  private

  def set_unit
    if params.has_key?(:id)
      @resource = Unit.find(params[:id])
    elsif params.has_key?(:suffix)
      @resource = Handle.find_by(prefix: params[:prefix],
                                 suffix: params[:suffix]).resource
    end
    @breadcrumbable = @resource
  end

  def authorize_unit
    @resource ? authorize(@resource) : skip_authorization
  end

  def assign_administrators
    # Non-primary administrators
    @resource.administrators.where(primary: false).destroy_all
    if params[:administering_users].respond_to?(:each)
      params[:administering_users].each do |user_str|
        user = User.from_autocomplete_string(user_str)
        @resource.errors.add(:administrators,
                             "includes a user that does not exist") unless user
        @resource.administering_users << user
      end
    end
    # Primary administrator
    @resource.primary_administrator =
        User.from_autocomplete_string(params[:primary_administrator])
  end

  def unit_params
    params.require(:unit).permit(:title, :parent_id)
  end
end
