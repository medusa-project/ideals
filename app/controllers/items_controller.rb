# frozen_string_literal: true

class ItemsController < ApplicationController
  before_action :set_item, only: [:show, :edit, :update, :destroy]

  # GET /items
  # GET /items.json
  def index
    @start = params[:start].to_i
    @limit = params[:per_page]&.to_i || 25
    finder = Item.search.
        query_all(params[:q]).
        start(@start).
        limit(@limit)
    @count            = finder.count
    @resources        = finder.to_a
    @current_page     = finder.page
    @permitted_params = params.permit(:q, :start)
  end

  # GET /items/1
  # GET /items/1.json
  def show
    raise ActiveRecord::RecordNotFound unless @resource

    @breadcrumbable = @resource
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

  # Use callbacks to share common setup or constraints between actions.
  def set_item
    if params.has_key?(:id)
      @resource = Item.find_by(id: params[:id])
    elsif params.has_key?(:suffix)
      @resource = Handle.find_by(prefix: params[:prefix], suffix: params[:suffix]).resource
    end
    @breadcrumbable = @resource
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def item_params
    params.require(:item).permit(:title,
                                 :submitter_email,
                                 :submitter_auth_provider,
                                 :in_archive, :withdrawn,
                                 :collection_id,
                                 :discoverable)
  end
end
