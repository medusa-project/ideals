class CollectionsController < ApplicationController
  load_and_authorize_resource
  skip_load_resource only: [:new, :create]

  # GET /collections
  # GET /collections.json
  def index
    @collections = Collection.all
  end

  # GET /collections/1
  # GET /collections/1.json
  def show
  end

  # GET /collections/new
  def new
    @collection = Collection.new
  end

  # GET /collections/1/edit
  def edit; end

  # POST /collections
  # POST /collections.json
  def create
    @collection = Collection.new(collection_params)

    respond_to do |format|
      if @collection.save

        if current_user&.role == Ideals::UserRole::MANAGER
          manager = Manager.from_user(user)
          raise "user with manager role not found in manager query #{user.provider} | #{user.uid}" unless manager
          @collection.managers << manager
        end
        format.html { redirect_to @collection, notice: 'Collection was successfully created.' }
        format.json { render :show, status: :created, location: @collection }
      else
        format.html { render :new }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /collections/1/add_manager
  def add_manager
    respond_to do |format|
      if params.has_key?(:manager_id) && @collection.add_manager(params[:manager_id])
        format.html { redirect_to @collection, notice: 'Manager was successfully assigned.' }
        format.json { render :show, status: :ok, location: @collection }
      else
        format.html { render :show, notice: 'Error when attempting to assign manager. Details have been logged.' }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /collections/1/remove_manager
  def remove_manager
    respond_to do |format|
      if params.has_key?(:manager_id) && @collection.remove_manager(params[:manager_id])
        format.html { redirect_to @collection, notice: 'Manager was successfully removed.' }
        format.json { render :show, status: :ok, location: @collection }
      else
        format.html { render :show, notice: 'Error when attempting to remove manager. Details have been logged.' }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /collections/1
  # PATCH/PUT /collections/1.json
  def update
    respond_to do |format|
      if @collection.update(collection_params)
        format.html { redirect_to @collection, notice: 'Collection was successfully updated.' }
        format.json { render :show, status: :ok, location: @collection }
      else
        format.html { render :edit }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /collections/1
  # DELETE /collections/1.json
  def destroy
    @collection.destroy
    respond_to do |format|
      format.html { redirect_to collections_url, notice: 'Collection was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def collections
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_collection
      @collection = Collection.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def collection_params
      params.require(:collection).permit(:title, :description, :manager_id)
    end
end
