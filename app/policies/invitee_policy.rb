class InviteePolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This invitee resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param invitee [Invitee]
  #
  def initialize(request_context, invitee)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role_limit      = request_context&.role_limit || Role::NO_LIMIT
    @invitee         = invitee
  end

  def approve
    if @invitee.respond_to?(:institution) &&
      @ctx_institution != @invitee.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @ctx_institution, @role_limit)
  end

  def create
    effective_institution_admin(@user, @ctx_institution, @role_limit)
  end

  def create_unsolicited
    logged_out
  end

  def destroy
    approve
  end

  def index
    create
  end

  def index_all
    effective_sysadmin(@user, @role_limit)
  end

  def new
    logged_out
  end

  def reject
    approve
  end

  def resend_email
    approve
  end

  def show
    approve
  end


  private

  def logged_out
    @user.nil? ? AUTHORIZED_RESULT :
      { authorized: false,
        reason: "You cannot perform this action while logged in." }
  end

end
