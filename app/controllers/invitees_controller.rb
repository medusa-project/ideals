# frozen_string_literal: true

class InviteesController < ApplicationController
  load_and_authorize_resource
  skip_authorize_resource only: [:new]
  before_action :set_invitee, only: [:show, :edit, :update, :destroy]
  helper_method :current_user, :logged_in?

  # GET /invitees
  # GET /invitees.json
  def index
    @pending_invitees = Invitee.where(approval_state: Ideals::ApprovalState::PENDING)
    @approved_invitees = Invitee.where(approval_state: Ideals::ApprovalState::APPROVED)
    @rejected_invitees = Invitee.where(approval_state: Ideals::ApprovalState::REJECTED)
  end

  # GET /invitees/1
  # GET /invitees/1.json
  def show; end

  # GET /invitees/new
  def new
    @invitee = Invitee.new
    @invitee.expires_at = Time.zone.now + 1.year
  end

  # GET /invitees/1/edit
  def edit; end

  # POST /invitees
  # POST /invitees.json
  def create
    @invitee = Invitee.new(invitee_params)

    respond_to do |format|
      if @invitee.save
        if current_user && current_user.role == Ideals::UserRole::ADMIN
          format.html { redirect_to invitees_path, notice: "New non-NetID IDEALS identity created." }
          format.json { render :show, status: :created, location: @invitee }
        else
          format.html { redirect_to :root_url, notice: "Request for non-NetID IDEALS identity submitted." }
          format.json { render json: {status: :created}, status: :created}
        end
      else
        format.html { render :new }
        format.json { render json: @invitee.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /invitees/1
  # PATCH/PUT /invitees/1.json
  def update
    respond_to do |format|
      if @invitee.update(invitee_params)
        format.html { redirect_to @invitee, notice: "Invitee was successfully updated." }
        format.json { render :show, status: :ok, location: @invitee }
      else
        format.html { render :edit }
        format.json { render json: @invitee.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /invitees/1
  # DELETE /invitees/1.json
  def destroy
    @invitee.destroy
    respond_to do |format|
      format.html { redirect_to invitees_url, notice: "Invitee was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_invitee
    @invitee = Invitee.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def invitee_params
    params.require(:invitee).permit(:email, :role, :note, :expires_at, :approval_state)
  end
end
