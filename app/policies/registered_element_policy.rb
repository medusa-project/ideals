# frozen_string_literal: true

class RegisteredElementPolicy < ApplicationPolicy
  attr_reader :user, :role, :registered_element

  ##
  # @param user_context [UserContext]
  # @param registered_element [RegisteredElement]
  #
  def initialize(user_context, registered_element)
    @user               = user_context&.user
    @role               = user_context&.role_limit
    @registered_element = registered_element
  end

  def create?
    if user
      return true if role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?
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
