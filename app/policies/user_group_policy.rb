class UserGroupPolicy < ApplicationPolicy

  attr_reader :user, :institution, :role, :user_group

  ##
  # @param request_context [RequestContext]
  # @param user_group [UserGroup]
  #
  def initialize(request_context, user_group)
    @user        = request_context&.user
    @institution = request_context&.institution
    @role        = request_context&.role_limit
    @user_group  = user_group
  end

  def create
    if !user
      return LOGGED_OUT_RESULT
    elsif (role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?) ||
        (role >= Role::INSTITUTION_ADMINISTRATOR && user.institution_administrators.count > 0) ||
        (role >= Role::UNIT_ADMINISTRATOR && user.unit_administrators.count > 0) ||
        (role >= Role::COLLECTION_MANAGER && user.managers.count > 0) # IR-67
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason: "You must be an administrator of an institution or unit, or a "\
              "manager of a collection." }
  end

  def destroy
    result = create
    if !result[:authorized] || user_group.required?
      return { authorized: false,
               reason:     "This group cannot be deleted." }
    end
    result
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

  def edit_local_users
    edit
  end

  def edit_netid_users
    edit
  end

  def index
    create
  end

  def index_global
    effective_sysadmin(user, role)
  end

  def new
    create
  end

  def show
    user_group.institution ? index : index_global
  end

  def update
    create
  end
end
