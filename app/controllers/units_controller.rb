# frozen_string_literal: true

class UnitsController < ApplicationController
  before_action :set_unit, only: [:show, :edit, :update, :destroy]

  # GET /units
  # GET /units.json
  def index
    finder = Unit.search.
        include_children(false).
        order("#{Unit::IndexFields::TITLE}.sort").
        limit(9999)
    @resources = finder.to_a
  end

  # GET /units/1
  # GET /units/1.json
  def show
    raise ActiveRecord::RecordNotFound unless @resource

    @breadcrumbable = @resource
    @collections = Collection.search.
        primary_unit(@resource).
        order("#{Collection::IndexFields::TITLE}.sort").
        limit(9999).
        to_a
    @new_collection = Collection.new
  end

  # GET /units/new
  def new
    @resource = Unit.new
  end

  # GET /units/1/edit
  def edit; end

  # POST /units
  # POST /units.json
  def create
    @resource = Unit.new(unit_params)

    respond_to do |format|
      if @resource.save
        format.html { redirect_to @resource, notice: "Unit was successfully created." }
        format.json { render :show, status: :created, location: @resource }
      else
        format.html { render :new }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /units/1
  # PATCH/PUT /units/1.json
  def update
    respond_to do |format|
      if @resource.update(unit_params)
        format.html { redirect_to @resource, notice: "Collection group was successfully updated." }
        format.json { render :show, status: :ok, location: @resource }
      else
        format.html { render :edit }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /units/1
  # DELETE /units/1.json
  def destroy
    @resource.destroy
    respond_to do |format|
      format.html { redirect_to units_url, notice: "Unit was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_unit
    if params.has_key?(:id)
      @resource = Unit.find_by(id: params[:id])
    elsif params.has_key?(:suffix)
      @resource = Handle.find_by(prefix: params[:prefix], suffix: params[:suffix]).resource
    end
    @breadcrumbable = @resource
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def unit_params
    params.require(:unit).permit(:title, :parent_id)
  end
end
