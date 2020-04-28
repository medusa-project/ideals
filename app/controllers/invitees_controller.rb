# frozen_string_literal: true

class InviteesController < ApplicationController

  before_action :ensure_logged_in, except: [:create, :new]
  before_action :ensure_logged_out, only: :new
  before_action :set_invitee, only: [:destroy, :update]
  before_action :authorize_invitee, only: [:destroy, :update]

  ##
  # Handles input from the invite-user form. Note that there are two such
  # forms: one that is public (for requesting an account) and one that is
  # sysadmin-only (for inviting a user to register). But it should be safe for
  # this handler to be public as it works the same for both.
  #
  # Responds to `POST /invitees`
  #
  def create
    @invitee = Invitee.new(invitee_params)
    authorize(@invitee)
    begin
      @invitee.save!
    rescue => e
      if request.xhr?
        render partial: "shared/validation_messages",
               locals: { object: @invitee.errors.any? ? @invitee : e },
               status: :bad_request
      else
        flash['error'] = "#{e}"
        redirect_to new_invitee_url, status: :bad_request
      end
    else
      flash['success'] = "An invitation has been sent to #{@invitee.email}."
      if request.xhr?
        render "shared/reload"
      else
        redirect_to root_url
      end
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
  # Responds to `GET /invitees`
  #
  def index
    authorize(Invitee)
    @start    = results_params[:start].to_i
    @window   = window_size
    @invitees = Invitee.
        where("email LIKE ?", "%#{params[:q]}%").
        order(created_at: :desc).
        limit(@window).
        offset(@start)
    @count            = @invitees.count
    @current_page     = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
    @permitted_params = results_params
    @new_invitee      = Invitee.new
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

  def invitee_params
    params.require(:invitee).permit(:email, :note)
  end

  def results_params
    params.permit(:class, :q, :start, :window)
  end

  def set_invitee
    @invitee = Invitee.find(params[:id])
  end

end
