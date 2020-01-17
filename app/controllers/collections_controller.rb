# frozen_string_literal: true

class CollectionsController < ApplicationController
  before_action :set_collection, only: [:show, :edit, :update, :destroy]

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
      finder = ItemFinder.new.
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

  # POST /collections
  # POST /collections.json
  def create
    @resource = Collection.new(collection_params)

    respond_to do |format|
      if @resource.save
        format.html { redirect_to @resource, notice: "Collection was successfully created." }
        format.json { render :show, status: :created, location: @resource }
      else
        format.html { render :new }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
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

  # DELETE /collections/1
  # DELETE /collections/1.json
  def destroy
    @resource.destroy
    respond_to do |format|
      format.html { redirect_to collections_url, notice: "Collection was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_collection
    if params.has_key?(:id)
      @resource = Collection.find_by(id: params[:id])
    elsif params.has_key?(:suffix)
      @resource = Handle.find_by(prefix: params[:prefix], suffix: params[:suffix]).resource
    end
    @breadcrumbable = @resource
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def collection_params
    params.require(:collection).permit(:title, :description)
  end
end
