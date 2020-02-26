# frozen_string_literal: true

class UserGroupPolicy < ApplicationPolicy
  attr_reader :user, :user_group

  ##
  # @param user [User]
  # @param user_group [UserGroup]
  #
  def initialize(user, user_group)
    @user        = user
    @user_group  = user_group
  end

  def create?
    user&.sysadmin?
  end

  def destroy?
    create?
  end

  def edit?
    update?
  end

  def index?
    user&.sysadmin?
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
