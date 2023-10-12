# frozen_string_literal: true

##
# N.B.: see the documentation of {Invitee} for a detailed overview of the
# invitation & registration process.
#
class InviteesController < ApplicationController

  before_action :ensure_institution_host
  before_action :ensure_logged_in, except: [:create_unsolicited, :register]
  before_action :ensure_logged_out, only: [:create_unsolicited, :register]
  before_action :set_invitee, only: [:approve, :destroy, :edit, :reject,
                                     :resend_email, :show]
  before_action :authorize_invitee, only: [:approve, :destroy, :edit, :reject,
                                           :resend_email, :show]
  before_action :store_location, only: [:index, :index_all, :show]

  ##
  # Performs the opposite action as {reject}. Institution admins only.
  #
  # Responds to `PATCH/POST /invitees/:id/approve`.
  #
  def approve
    @invitee.approve
  rescue => e
    flash['error'] = "#{e}"
    redirect_back fallback_location: invitees_path
  else
    toast!(title:   "Invitee approved",
           message: "The invitee #{@invitee.email} has been approved, and "\
                    "will be receiving an email notification shortly.")
    redirect_back fallback_location: invitees_path
  end

  ##
  # Handles input from the invite-user form (institution admins only). This is
  # one of two entry points for invitees, the other being {create_unsolicited}.
  #
  # Responds to `POST /invitees`.
  #
  # @see create_unsolicited
  #
  def create
    @invitee               = Invitee.new(invitee_params)
    @invitee.institution ||= current_institution
    authorize(@invitee)
    begin
      ActiveRecord::Base.transaction do
        @invitee.save!
        @invitee.invite
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @invitee.errors.any? ? @invitee : e },
             status: :bad_request
    else
      toast!(title:   "Invitation sent",
             message: "An invitation has been sent to #{@invitee.email}.")
      render "shared/reload"
    end
  end

  ##
  # Handles input from the public account-request form. This is one of two
  # entry points for invitees, the other being {create}.
  #
  # Responds to `POST /invitees/create-unsolicited`.
  #
  # @see create
  #
  def create_unsolicited
    @invitee             = Invitee.new(invitee_params)
    @invitee.institution = current_institution
    authorize(@invitee)
    begin
      raise "Incorrect math question response. Please try again." unless check_captcha
      ActiveRecord::Base.transaction do
        @invitee.save!
        @invitee.send_reception_emails
      end
    rescue => e
      flash['error'] = "#{e}"
      redirect_to register_path
    else
      flash['success'] = "Thanks for requesting an account! We will review "\
          "your request and act on it as soon as possible. When we do, we'll "\
          "notify you via email."
      redirect_to @invitee.institution.scope_url,
                  allow_other_host: true # TODO: remove this and fix tests
    end
  end

  ##
  # Institution admins only.
  #
  # Responds to `DELETE /invitees/:id`.
  #
  def destroy
    @invitee.destroy!
  rescue => e
    flash['error'] = "#{e}"
  else
    toast!(title:   "Invitee deleted",
           message: "The invitee #{@invitee.email} has been deleted.")
  ensure
    redirect_back fallback_location: invitees_url
  end

  ##
  # N.B. contrary to its name, this method is used to render the
  # reject-an-invitee form, which is the only way an invitee would need to be
  # edited.
  #
  # Responds to `GET /invitees/:id/edit`
  #
  def edit
    render partial: "reject_form"
  end

  ##
  # Responds to `GET /invitees`
  #
  def index
    authorize(Invitee)
    setup_index(current_institution)
    respond_to do |format|
      format.html
      format.js { render partial: "invitees" }
    end
  end

  def index_all
    authorize(Invitee)
    setup_index(nil)
    respond_to do |format|
      format.html
      format.js { render partial: "all_invitees" }
    end
  end

  ##
  # Renders the invite-user form, which is only accessible by logged-in
  # institution admins. {create} handles the form submission.
  #
  # Responds to `GET /invitees/new`
  #
  # @see register
  #
  def new
    authorize Invitee
    if params.dig(:invitee, :institution_id).blank?
      render plain: "Missing institution ID", status: :bad_request
      return
    end
    @invitee = Invitee.new(expires_at: Time.zone.now + 1.year)
    render partial: "new_form"
  end

  ##
  # The logged-out counterpart to {new} which renders the account-request form.
  # This is one of two pathways into the registration form, the other being an
  # invite from a sysadmin which goes to {new}. {create_unsolicited} handles
  # the form submission.
  #
  # Responds to `GET /invitees/register`
  #
  # @see new
  #
  def register
    @invitee = Invitee.new(expires_at: Time.zone.now + 1.year)
  end

  ##
  # Performs the opposite action as {approve}. Institution admins only.
  #
  # Responds to `PATCH/POST /invitees/:id/reject`.
  #
  def reject
    reason = invitee_params[:rejection_reason] rescue nil
    @invitee.reject(reason: reason)
  rescue => e
    flash['error'] = "#{e}"
    redirect_back fallback_location: invitees_path
  else
    toast!(title:   "Invitee rejected",
           message: "The invitee #{@invitee.email} has been rejected and "\
                    "will be receiving an email notification shortly.")
    redirect_back fallback_location: invitees_path
  end

  ##
  # Institution admins only.
  #
  # Responds to `PATCH/POST /invitees/:id/resend-email`.
  #
  def resend_email
    @invitee.send_approval_email
  rescue => e
    flash['error'] = "#{e}"
    redirect_back fallback_location: invitees_path
  else
    toast!(title:   "Email re-sent",
           message: "An email has been sent to #{@invitee.email}.")
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
    params.require(:invitee).permit(:email, :institution_admin,
                                    :institution_id, :inviting_user_id,
                                    :note, :rejection_reason)
  end

  def set_invitee
    @invitee = Invitee.find(params[:id] || params[:invitee_id])
    @breadcrumbable = @invitee
  end

  def setup_index(institution)
    @permitted_params = params.permit(Search::RESULTS_PARAMS +
                                        Search::SIMPLE_SEARCH_PARAMS +
                                        [:approval_state, :institution_id])
    @start            = [@permitted_params[:start].to_i.abs, MAX_START].min
    @window           = window_size
    @invitees         = Invitee.
      where("LOWER(email) LIKE ?", "%#{@permitted_params[:q]&.downcase}%").
      where(approval_state: @permitted_params[:approval_state] || Invitee::ApprovalState::PENDING).
      order(:created_at)
    if institution
      @invitees = @invitees.where(institution: institution)
    elsif params[:institution_id].present?
      @invitees = @invitees.where(institution_id: @permitted_params[:institution_id].to_i)
    end
    @count            = @invitees.count
    @invitees         = @invitees.limit(@window).offset(@start)
    @current_page     = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
    @new_invitee      = Invitee.new
  end

end
