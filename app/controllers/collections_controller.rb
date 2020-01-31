# frozen_string_literal: true

class CollectionsController < ApplicationController
  before_action :set_collection, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user, only: [:create, :edit, :destroy, :update]

  # GET /collections
  # GET /collections.json
  def index
    @resources = Collection.all
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

  # GET /collections/1/edit
  def edit; end

  ##
  # Responds to `POST /collections`
  #
  def create
    begin
      ActiveRecord::Base.transaction do
        @resource = Collection.new(collection_params)
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
      render 'shared/reload' # create.js.erb will reload the page
    end
  end

  # PATCH/PUT /collections/1
  # PATCH/PUT /collections/1.json
  def update
    respond_to do |format|
      if @resource.update(collection_params)
        format.html { redirect_to @resource, notice: "Collection was successfully updated." }
        format.json { render :show, status: :ok, location: @resource }
      else
        format.html { render :edit }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
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
    params.require(:collection).permit(:title, :primary_unit_id)
  end
end
