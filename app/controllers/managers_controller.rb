class ManagersController < ApplicationController
  load_and_authorize_resource
  before_action :set_manager, only: [:show, :edit, :update, :destroy, :take_on_collection, :collection_id]
  helper_method :current_user, :logged_in?

  # GET /managers
  # GET /managers.json
  def index
    @managers = Manager.all
  end

  # GET /managers/1
  # GET /managers/1.json
  def show
  end

  # GET /managers/new
  def new
    @manager = Manager.new
  end

  # GET /managers/1/edit
  def edit
  end

  # POST /managers
  # POST /managers.json
  def create
    @manager = Manager.new(manager_params)

    respond_to do |format|
      if @manager.save
        format.html { redirect_to @manager, notice: 'Manager was successfully created.' }
        format.json { render :show, status: :created, location: @manager }
      else
        format.html { render :new }
        format.json { render json: @manager.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /managers/1
  # PATCH/PUT /managers/1.json
  def update
    respond_to do |format|
      if @manager.update(manager_params)
        format.html { redirect_to @manager, notice: 'Manager was successfully updated.' }
        format.json { render :show, status: :ok, location: @manager }
      else
        format.html { render :edit }
        format.json { render json: @manager.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /managers/1
  # DELETE /managers/1.json
  def destroy
    @manager.destroy
    respond_to do |format|
      format.html { redirect_to managers_url, notice: 'Manager was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # POST /managers/1/take_on_collection
  def take_on_collection
    respond_to do |format|
      if params.has_key?(:collection_id) && @manager.add_collection(params[:collection_id])
        format.html { redirect_to @manager, notice: 'Collection was successfully taken on.' }
        format.json { render :show, status: :ok, location: @manager }
      else
        format.html { render :show, notice: 'Error when attempting to take on collection. Details have been logged.' }
        format.json { render json: @manager.errors, status: :unprocessable_entity }
      end
    end

  end

  # POST /managers/1/release_collection
  def release_collection
    respond_to do |format|
      if params.has_key?(:collection_id) && @manager.remove_collection(params[:collection_id])
        format.html { redirect_to @manager, notice: 'Collection was successfully released.' }
        format.json { render :show, status: :ok, location: @manager }
      else
        format.html { render :show, notice: 'Error when attempting to release collection. Details have been logged.' }
        format.json { render json: @manager.errors, status: :unprocessable_entity }
      end
    end

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_manager
      @manager = Manager.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def manager_params
      params.require(:manager).permit(:uid, :provider, :collection_id)
    end
end
