class InviteePolicy < ApplicationPolicy

  attr_reader :user, :institution, :role, :invitee

  ##
  # @param request_context [RequestContext]
  # @param invitee [Invitee]
  #
  def initialize(request_context, invitee)
    @user        = request_context&.user
    @institution = request_context&.institution
    @role        = request_context&.role_limit || Role::NO_LIMIT
    @invitee     = invitee
  end

  def approve
    create
  end

  def create
    effective_institution_admin(user, institution, role)
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
    effective_sysadmin(user, role)
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
    index
  end


  private

  def logged_out
    user.nil? ? AUTHORIZED_RESULT :
      { authorized: false,
        reason: "You cannot perform this action while logged in." }
  end

end
