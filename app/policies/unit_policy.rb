# frozen_string_literal: true

class UnitPolicy < ApplicationPolicy
  attr_reader :user, :unit

  ##
  # @param user [User]
  # @param unit [Unit]
  #
  def initialize(user, unit)
    @user = user
    @unit = unit
  end

  def create?
    return false if unit == Unit
    user&.sysadmin? || unit.administrators.where(user_id: user.id).count > 0
  end

  def destroy?
    return false if unit == Unit
    # user is sysadmin
    user.sysadmin? ||
        # unit is a child unit and user is primary admin of its root unit.
        # (Note that the unit must also be empty of collections and child
        # units; this is validated in the model.)
        (unit.child? && user == unit.root_parent.primary_administrator)
  end

  def edit?
    update?
  end

  def index?
    true
  end

  def new?
    create?
  end

  def show?
    true
  end

  def update?
    create?
  end
end
