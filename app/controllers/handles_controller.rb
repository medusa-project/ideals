class HandlesController < ApplicationController
  before_action :set_handle, only: [:show, :edit, :update, :destroy]

  # GET /handles
  # GET /handles.json
  def index
    @handles = Handle.all
  end

  # GET /handles/1
  # GET /handles/1.json
  def show
  end

  # GET /handles/new
  def new
    @handle = Handle.new
  end

  # GET /handles/1/edit
  def edit
  end

  # POST /handles
  # POST /handles.json
  def create
    @handle = Handle.new(handle_params)

    respond_to do |format|
      if @handle.save
        format.html { redirect_to @handle, notice: 'Handle was successfully created.' }
        format.json { render :show, status: :created, location: @handle }
      else
        format.html { render :new }
        format.json { render json: @handle.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /handles/1
  # PATCH/PUT /handles/1.json
  def update
    respond_to do |format|
      if @handle.update(handle_params)
        format.html { redirect_to @handle, notice: 'Handle was successfully updated.' }
        format.json { render :show, status: :ok, location: @handle }
      else
        format.html { render :edit }
        format.json { render json: @handle.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /handles/1
  # DELETE /handles/1.json
  def destroy
    @handle.destroy
    respond_to do |format|
      format.html { redirect_to handles_url, notice: 'Handle was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # GET /handle/:prefix/:suffix
  def resolve

    handle = Handle.find_by(prefix: params[:prefix], suffix: params[:suffix])
    raise ActiveRecord::RecordNotFound unless handle

    klass_name = handle.klass_name

    @breadcrumbable = @resource = handle.resource
    @search = @resource.default_search

    if klass_name == 'CollectionGroup'
      render "#{collection_groups.downcase.pluralize(2)}/show"
    else
      render "#{klass_name.downcase.pluralize(2)}/show"
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_handle
      @handle = Handle.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def handle_params
      params.require(:handle).permit(:handle, :prefix, :suffix, :resource_type_id, :resource_id)
    end
end
