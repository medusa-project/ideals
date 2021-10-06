# frozen_string_literal: true

class UserGroupPolicy < ApplicationPolicy
  attr_reader :user, :role, :user_group

  ##
  # @param request_context [RequestContext]
  # @param user_group [UserGroup]
  #
  def initialize(request_context, user_group)
    @user        = request_context&.user
    @role        = request_context&.role_limit
    @user_group  = user_group
  end

  def create
    if !user
      return LOGGED_OUT_RESULT
    elsif (role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?) ||
        (role >= Role::UNIT_ADMINISTRATOR && user.administrators.count > 0) ||
        (role >= Role::COLLECTION_MANAGER && user.managers.count > 0) # IR-67
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason: "You must be a unit administrator or collection manager." }
  end

  def destroy
    create
  end

  def edit
    update
  end

  def edit_ad_groups
    edit
  end

  def edit_hosts
    edit
  end

  def edit_local_users
    edit
  end

  def index
    create
  end

  def new
    create
  end

  def show
    index
  end

  def update
    create
  end
end
