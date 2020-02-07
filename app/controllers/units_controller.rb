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
        if params[:primary_administrator_id]
          @resource.primary_administrator =
              User.find(params[:primary_administrator_id])
        end
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
    finder = Unit.search.
        include_children(false).
        order("#{Unit::IndexFields::TITLE}.sort").
        limit(9999)
    @resources = finder.to_a
    @new_unit = Unit.new
  end

  ##
  # Responds to `GET /units/new`
  #
  def new
    @resource = Unit.new
    authorize @resource
  end

  ##
  # Responds to GET /units/:id
  #
  def show
    raise ActiveRecord::RecordNotFound unless @resource

    @breadcrumbable = @resource
    @subunits = Unit.search.
        parent_unit(@resource).
        order("#{Unit::IndexFields::TITLE}.sort").
        limit(999).
        to_a
    @collections = Collection.search.
        primary_unit(@resource).
        order(RegisteredElement.sortable_field(::Configuration.instance.elements[:title])).
        limit(999).
        to_a
    @new_unit       = Unit.new
    @new_collection = Collection.new
  end

  ##
  # Responds to `PATCH/PUT /units/:id`
  #
  def update
    begin
      ActiveRecord::Base.transaction do
        @resource.update!(unit_params)
        if params[:primary_administrator_id]
          @resource.primary_administrator =
              User.find(params[:primary_administrator_id])
        end
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

  def unit_params
    params.require(:unit).permit({ administering_user_ids: [] },
                                 :title, :parent_id)
  end
end
