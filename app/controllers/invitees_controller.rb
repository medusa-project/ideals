# frozen_string_literal: true

class InviteesController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_invitee, only: [:destroy, :update]
  before_action :authorize_invitee, only: [:destroy, :update]

  ##
  # Handles input from the invite-user form.
  #
  # Responds to `POST /invitees` (XHR only)
  #
  def create
    @invitee = Invitee.new(invitee_params)
    authorize(@invitee)
    begin
      @invitee.save!
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @invitee.errors.any? ? @invitee : e },
             status: :bad_request
    else
      flash['success'] = "An invitation has been sent to #{@invitee.email}."
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /invitees/:id`
  #
  def destroy
    @invitee.destroy
    respond_to do |format|
      format.html { redirect_to invitees_url, notice: "Invitee was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  ##
  # Renders the account-request form, which is only accessible by logged-out
  # users. This is one of two pathways into the registration form, the other
  # being an invite from a sysadmin.
  #
  # Responds to `GET /invitees/new`
  #
  def new
    @invitee = Invitee.new
    @invitee.expires_at = Time.zone.now + 1.year
    authorize(@invitee)
  end

  ##
  # Responds to `PATCH/PUT /invitees/:id`
  #
  def update
    if @invitee.update(invitee_params)
      redirect_to @invitee, notice: "Invitee was successfully updated."
    else
      render :edit
    end
  end

  private

  def authorize_invitee
    @invitee ? authorize(@invitee) : skip_authorization
  end

  def set_invitee
    @invitee = Invitee.find(params[:id])
  end

  def invitee_params
    params.require(:invitee).permit(:email, :note)
  end

end
