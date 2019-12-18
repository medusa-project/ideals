# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user.sysadmin?
  end

  def show?
    user.sysadmin?
  end

  def create?
    user.sysadmin?
  end

  def new?
    create?
  end

  def update?
    user.sysadmin?
  end

  def edit?
    update?
  end

  def destroy?
    user.sysadmin?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end
end
