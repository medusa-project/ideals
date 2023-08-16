class UserGroupPolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This user group resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param user_group [UserGroup]
  #
  def initialize(request_context, user_group)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role_limit      = request_context&.role_limit || Role::NO_LIMIT
    @user_group      = user_group
  end

  def create
    index
  end

  def destroy
    if @user_group.required?
      return { authorized: false,
               reason:     "This group cannot be deleted." }
    end
    update
  end

  def edit
    update
  end

  def edit_ad_groups
    edit
  end

  def edit_affiliations
    edit
  end

  def edit_departments
    edit
  end

  def edit_email_patterns
    edit
  end

  def edit_hosts
    edit
  end

  def edit_users
    edit
  end

  def index
    effective_institution_admin(@user, @ctx_institution, @role_limit)
  end

  def index_global
    effective_sysadmin(@user, @role_limit)
  end

  def new
    create
  end

  def show
    @user_group.institution ? update : index_global
  end

  def update
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @user_group.institution && @ctx_institution != @user_group.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @user_group.institution, @role_limit)
  end
end
