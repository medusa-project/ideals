# frozen_string_literal: true

class ItemsController < ApplicationController
  before_action :set_item, only: [:show, :edit, :update, :destroy]

  ##
  # Responds to `GET /items`
  #
  def index
    @start  = results_params[:start].to_i
    @window = window_size
    @items = Item.search.
        aggregations(true).
        query_all(results_params[:q]).
        facet_filters(results_params[:fq]).
        start(@start).
        limit(@window)
    @count            = @items.count
    @facets           = @items.facets
    @current_page     = @items.page
    @permitted_params = results_params
  end

  ##
  # Responds to `GET /items/:id`
  #
  def show
    template = "show"
    if @resource.withdrawn
      render template, status: :gone
    elsif !@resource.discoverable
      render template, status: :forbidden
    elsif !@resource.in_archive
      render template, status: :forbidden
    end
  end

  # GET /items/new
  def new
    @resource = Item.new
  end

  # GET /items/1/edit
  def edit; end

  # POST /items
  # POST /items.json
  def create
    @resource = Item.new(item_params)

    respond_to do |format|
      if @resource.save
        format.html { redirect_to @resource, notice: "Item was successfully created." }
        format.json { render :show, status: :created, location: @resource }
      else
        format.html { render :new }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /items/1
  # PATCH/PUT /items/1.json
  def update
    respond_to do |format|
      if @resource.update(item_params)
        format.html { redirect_to @resource, notice: "Item was successfully updated." }
        format.json { render :show, status: :ok, location: @resource }
      else
        format.html { render :edit }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.json
  def destroy
    @resource.destroy
    respond_to do |format|
      format.html { redirect_to items_url, notice: "Item was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_item
    if params.has_key?(:id)
      @resource = Item.find(params[:id])
    elsif params.has_key?(:suffix)
      @resource = Handle.find_by(prefix: params[:prefix], suffix: params[:suffix]).resource
    end
    @breadcrumbable = @resource
  end

  def item_params
    params.require(:item).permit(:title,
                                 :submitter_email,
                                 :submitter_auth_provider,
                                 :in_archive, :withdrawn,
                                 :collection_id,
                                 :discoverable)
  end

end