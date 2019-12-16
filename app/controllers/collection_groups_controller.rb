class CollectionGroupsController < ApplicationController
  before_action :set_collection_group, only: [:show, :edit, :update, :destroy]

  # GET /collection_groups
  # GET /collection_groups.json
  def index
    @resources = CollectionGroup.top
  end

  # GET /collection_groups/1
  # GET /collection_groups/1.json
  def show
    raise ActiveRecord::RecordNotFound unless @resource
  end

  # GET /collection_groups/new
  def new
    @resource = CollectionGroup.new
  end

  # GET /collection_groups/1/edit
  def edit
  end

  # POST /collection_groups
  # POST /collection_groups.json
  def create
    @resource = CollectionGroup.new(collection_group_params)

    respond_to do |format|
      if @resource.save
        format.html { redirect_to @resource, notice: 'Collection group was successfully created.' }
        format.json { render :show, status: :created, location: @resource }
      else
        format.html { render :new }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /collection_groups/1
  # PATCH/PUT /collection_groups/1.json
  def update
    respond_to do |format|
      if @resource.update(collection_group_params)
        format.html { redirect_to @resource, notice: 'Collection group was successfully updated.' }
        format.json { render :show, status: :ok, location: @resource }
      else
        format.html { render :edit }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /collection_groups/1
  # DELETE /collection_groups/1.json
  def destroy
    @resource.destroy
    respond_to do |format|
      format.html { redirect_to collection_groups_url, notice: 'Collection group was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_collection_group
      if params.has_key?(:id)
        @resource = CollectionGroup.find_by(id: params[:id])
      elsif params.has_key?(:suffix)
        @resource = Handle.find_by(prefix: params[:prefix], suffix: params[:suffix]).resource
      end
      @breadcrumbable = @resource
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def collection_group_params
      params.require(:collection_group).permit(:title, :group_id, :parent_group_id)
    end
end
