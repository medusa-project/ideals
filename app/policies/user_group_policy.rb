# frozen_string_literal: true

class UserGroupPolicy < ApplicationPolicy
  attr_reader :user, :role, :user_group

  ##
  # @param user_context [UserContext]
  # @param user_group [UserGroup]
  #
  def initialize(user_context, user_group)
    @user        = user_context&.user
    @role        = user_context&.role_limit
    @user_group  = user_group
  end

  def create?
    if user # IR-67
      return true if (role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?) ||
          (role >= Role::UNIT_ADMINISTRATOR && user.administrators.count > 0) ||
          (role >= Role::COLLECTION_MANAGER && user.managers.count > 0)
    end
    false
  end

  def destroy?
    create?
  end

  def edit?
    update?
  end

  def index?
    create?
  end

  def new?
    create?
  end

  def show?
    index?
  end

  def update?
    create?
  end
end
