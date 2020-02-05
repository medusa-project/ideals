# frozen_string_literal: true

class CollectionsController < ApplicationController
  before_action :set_collection, only: [:show, :edit, :update, :destroy]
  before_action :ensure_logged_in, except: :show

  ##
  # Responds to `POST /collections`
  #
  def create
    begin
      @resource = Collection.new(collection_params)
      ActiveRecord::Base.transaction do
        @resource.save!
        @resource.primary_unit = Unit.find(params[:primary_unit_id])
        @resource.save!
      end
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @resource },
             status: :bad_request
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Collection \"#{@resource.title}\" created."
      render 'shared/reload'
    end
  end

  ##
  # Responds to GET /collections/:id/edit (XHR only)
  #
  def edit
    collection = Collection.find(params[:id])
    render partial: 'collections/form',
           locals: { collection: collection,
                     primary_unit: collection.primary_unit,
                     context: :edit }
  end

  # GET /collections/1
  # GET /collections/1.json
  def show
    if @resource.items.count.positive?
      @start = params[:start].to_i
      @limit = params[:per_page]&.to_i || 25
      finder = Item.search.
          collection(params[:id]).
          start(@start).
          limit(@limit)
      @count            = finder.count
      @resources        = finder.to_a
      @current_page     = finder.page
      @permitted_params = params.permit(:q, :start)
    end
    @breadcrumbable = @resource
  end

  # GET /collections/new
  def new
    @resource = Collection.new
  end

  ##
  # Responds to PATCH/PUT /collections/:id
  #
  def update
    begin
      @resource = Collection.find(params[:id])
      ActiveRecord::Base.transaction do
        @resource.update!(collection_params)
        if params[:primary_unit_id]
          @resource.primary_unit = Unit.find(params[:primary_unit_id])
        end
        @resource.save!
      end
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @resource },
             status: :bad_request
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Collection \"#{@resource.title}\" updated."
      render 'shared/reload'
    end
  end

  ##
  # Responds to DELETE /collections/:id
  #
  def destroy
    collection = Collection.find(params[:id])
    primary_unit = collection.primary_unit
    begin
      ActiveRecord::Base.transaction do
        collection.destroy!
      end
    rescue => e
      flash['error'] = "#{e}"
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Collection \"#{collection.title}\" deleted."
    ensure
      redirect_to primary_unit
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_collection
    if params.has_key?(:id)
      @resource = Collection.find(params[:id])
    elsif params.has_key?(:suffix)
      @resource = Handle.find_by(prefix: params[:prefix], suffix: params[:suffix]).resource
    end
    @breadcrumbable = @resource
  end

  def collection_params
    params.require(:collection).permit({managing_user_ids: [] }, :title)
  end
end
