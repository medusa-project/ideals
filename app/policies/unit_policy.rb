# frozen_string_literal: true

class UnitPolicy < ApplicationPolicy
  attr_reader :user, :role, :unit

  ##
  # @param request_context [RequestContext]
  # @param unit [Unit]
  #
  def initialize(request_context, unit)
    @user = request_context&.user
    @role = request_context&.role_limit
    @unit = unit
  end

  ##
  # Invoked from {UnitsController#update} to ensure that a user cannot move a
  # unit to another unit of which s/he is not an effective administrator.
  #
  def change_parent?(new_parent_id)
    if user
      return true if new_parent_id == unit.parent_id
      return true if role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?
      if role >= Role::UNIT_ADMINISTRATOR
        return user.effective_unit_admin?(Unit.find(new_parent_id))
      end
    end
    false
  end

  def children?
    true
  end

  def collections_tree_fragment?
    true
  end

  def create?
    if user
      return true if role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?
      return true if unit != Unit &&
        role >= Role::INSTITUTION_ADMINISTRATOR &&
        user.institution_admin?(user.institution)
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
    show_access?
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

  def item_download_counts?
    show_statistics?
  end

  def new?
    create?
  end

  def show?
    true
  end

  def show_access?
    update?
  end

  def show_collections?
    show?
  end

  def show_items?
    show?
  end

  def show_properties?
    show?
  end

  def show_statistics?
    show?
  end

  def show_unit_membership?
    show?
  end

  def statistics_by_range?
    show_statistics?
  end

  def update?
    if user
      return true if role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?
      return true if unit != Unit &&
        role >= Role::UNIT_ADMINISTRATOR &&
        unit.administrators.where(user_id: user.id).count > 0
    end
    false
  end
end
