# frozen_string_literal: true

##
# N.B.: see the documentation of {Invitee} for a detailed overview of the
# invitation & registration process.
#
class InviteesController < ApplicationController

  before_action :ensure_logged_in, except: [:create_unsolicited, :new]
  before_action :ensure_logged_out, only: [:create_unsolicited, :new]
  before_action :set_invitee, only: [:approve, :destroy, :reject, :resend_email,
                                     :show]
  before_action :authorize_invitee, only: [:approve, :destroy, :reject,
                                           :resend_email, :show]

  ##
  # Performs the opposite action as {reject}. Sysadmin-only.
  #
  # Responds to `PATCH/POST /invitees/:id/approve`.
  #
  def approve
    @invitee.approve
  rescue => e
    flash['error'] = "#{e}"
    redirect_back fallback_location: invitees_path
  else
    flash['success'] = "Invitee #{@invitee.email} has been approved and will "\
        "be receiving an email notification shortly."
    redirect_to invitees_path
  end

  ##
  # Handles input from the sysadmin-only invite-user form. This is one of two
  # entry points of local-identity users into the system, the other being
  # {create_unsolicited}.
  #
  # Responds to `POST /invitees` (XHR only).
  #
  # @see create_unsolicited
  #
  def create
    @invitee = Invitee.new(invitee_params)
    authorize(@invitee)
    begin
      @invitee.save!
      @invitee.invite
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
  # Handles input from the public account-request form. This is one of two
  # entry points of local-identity users into the system, the other being
  # {create}.
  #
  # Responds to `POST /invitees/create`.
  #
  # @see create
  #
  def create_unsolicited
    @invitee = Invitee.new(invitee_params)
    authorize(@invitee)
    begin
      @invitee.save!
      @invitee.send_reception_emails
    rescue => e
      flash['error'] = "#{e}"
      redirect_to new_invitee_url
    else
      flash['success'] = "Thanks for requesting an IDEALS account! IDEALS "\
          "staff will review your request and act on it as soon as possible. "\
          "When we do, we'll notify you via email."
      redirect_to root_url
    end
  end

  ##
  # Responds to `DELETE /invitees/:id`. Sysadmin-only.
  #
  def destroy
    @invitee.destroy!
  rescue => e
    flash['error'] = "#{e}"
  else
    flash['success'] = "Invitee #{@invitee.email} has been deleted."
  ensure
    redirect_to invitees_url
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
        where("approval_state LIKE ?", "%#{params[:approval_state]}%").
        order(:created_at).
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
  # being an invite from a sysadmin. {create_unsolicited} handles the form
  # submission.
  #
  # Responds to `GET /invitees/new`
  #
  def new
    @invitee = Invitee.new(expires_at: Time.zone.now + 1.year)
    authorize(@invitee)
  end

  ##
  # Performs the opposite action as {approve}.
  #
  # Responds to `PATCH/POST /invitees/:id/reject`. Sysadmin-only.
  #
  def reject
    @invitee.reject
  rescue => e
    flash['error'] = "#{e}"
    redirect_back fallback_location: invitees_path
  else
    flash['success'] = "Invitee #{@invitee.email} has been rejected and will "\
        "be receiving an email notification shortly."
    redirect_to invitees_path
  end

  ##
  # Responds to `PATCH/POST /invitees/:id/resend-email`. Sysadmin-only.
  #
  def resend_email
    @invitee.send_approval_email
  rescue => e
    flash['error'] = "#{e}"
    redirect_back fallback_location: invitees_path
  else
    flash['success'] = "An email has been sent to #{@invitee.email}."
    redirect_to invitees_path
  end

  ##
  # Responds to `GET /invitees/:id`
  #
  def show
  end

  private

  def authorize_invitee
    @invitee ? authorize(@invitee) : skip_authorization
  end

  def invitee_params
    params.require(:invitee).permit(:email, :note)
  end

  def results_params
    params.permit(:approval_state, :class, :q, :start, :window)
  end

  def set_invitee
    @invitee = Invitee.find(params[:id] || params[:invitee_id])
  end

end
