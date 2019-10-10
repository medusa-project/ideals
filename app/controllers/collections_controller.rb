class CollectionsController < ApplicationController
  before_action :set_collection, only: [:show, :edit, :update, :destroy, :add_manager, :remove_manager]

  # GET /collections
  # GET /collections.json
  def index
    @resources = Collection.all
  end

  # GET /collections/1
  # GET /collections/1.json
  def show
    if @resource.items.count.positive?
      resource_id = @resource.id
      @item_search = Item.search do
        with :collection_id, resource_id
        fulltext params[:q]
        if params.has_key?(:per_page)
          per_page = params[:per_page].to_i
        else
          per_page = 25
        end
        paginate(page: params[:page] || 1, per_page: per_page)
      end
    end
  end

  # GET /collections/new
  def new
    @resource = Collection.new
  end

  # GET /collections/1/edit
  def edit
    authorize!
  end

  # POST /collections
  # POST /collections.json
  def create
    authorize!
    @resource = Collection.new(collection_params)

    respond_to do |format|
      if @resource.save

        if current_user&.role == Ideals::UserRole::MANAGER
          manager = Manager.from_user(user)
          raise "user with manager role not found in manager query #{user.provider} | #{user.uid}" unless manager
          @resource.managers << manager
        end
        format.html { redirect_to @resource, notice: 'Collection was successfully created.' }
        format.json { render :show, status: :created, location: @resource }
      else
        format.html { render :new }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /collections/1/add_manager
  def add_manager
    authorize!
    respond_to do |format|
      if params.has_key?(:manager_id) && @resource.add_manager(params[:manager_id])
        format.html { redirect_to @resource, notice: 'Manager was successfully assigned.' }
        format.json { render :show, status: :ok, location: @resource }
      else
        format.html { render :show, notice: 'Error when attempting to assign manager. Details have been logged.' }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /collections/1/remove_manager
  def remove_manager
    authorize!
    respond_to do |format|
      if params.has_key?(:manager_id) && @resource.remove_manager(params[:manager_id])
        format.html { redirect_to @resource, notice: 'Manager was successfully removed.' }
        format.json { render :show, status: :ok, location: @resource }
      else
        format.html { render :show, notice: 'Error when attempting to remove manager. Details have been logged.' }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /collections/1
  # PATCH/PUT /collections/1.json
  def update
    authorize!
    respond_to do |format|
      if @resource.update(collection_params)
        format.html { redirect_to @resource, notice: 'Collection was successfully updated.' }
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
    authorize!
    @resource.destroy
    respond_to do |format|
      format.html { redirect_to collections_url, notice: 'Collection was successfully destroyed.' }
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
      params.require(:collection).permit(:title, :description, :manager_id)
    end
end
