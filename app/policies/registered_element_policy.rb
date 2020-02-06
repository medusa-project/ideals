# frozen_string_literal: true

class RegisteredElementPolicy < ApplicationPolicy
  attr_reader :user, :registered_element

  ##
  # @param user [User]
  # @param registered_element [RegisteredElement]
  #
  def initialize(user, registered_element)
    @user               = user
    @registered_element = registered_element
  end

  def create?
    user.sysadmin?
  end

  def destroy?
    create?
  end

  def edit?
    update?
  end

  def index?
    user.sysadmin?
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
