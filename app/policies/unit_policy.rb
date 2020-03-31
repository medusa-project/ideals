# frozen_string_literal: true

class UnitPolicy < ApplicationPolicy
  attr_reader :user, :role, :unit

  ##
  # @param user_context [UserContext]
  # @param unit [Unit]
  #
  def initialize(user_context, unit)
    @user = user_context&.user
    @role = user_context&.role_limit
    @unit = unit
  end

  def children?
    true
  end

  def collections?
    true
  end

  def create?
    if user
      return true if role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?
      return true if unit != Unit &&
          role >= Role::UNIT_ADMINISTRATOR &&
          unit.administrators.where(user_id: user.id).count > 0
    end
    false
  end

  def destroy?
    if user
      # user is sysadmin
      (role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?) ||
          # unit is a child unit and user is primary admin of its root unit.
          # (Note that the unit must also be empty of collections and child
          # units; this is validated in the model.)
          (unit.child? && Role::UNIT_ADMINISTRATOR &&
              user == unit.root_parent.primary_administrator)
    end
  end

  def edit_access?
    update?
  end

  def edit_membership?
    update?
  end

  def edit_properties?
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
