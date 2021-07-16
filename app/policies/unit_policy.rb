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
  def change_parent(new_parent_id)
    if user
      return AUTHORIZED_RESULT if new_parent_id == unit.parent_id
      return AUTHORIZED_RESULT if role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?
      return AUTHORIZED_RESULT if role >= Role::UNIT_ADMINISTRATOR &&
        user.effective_unit_admin?(Unit.find(new_parent_id))
    end
    { authorized: false,
      reason:     "You must be an administrator of the desired parent unit." }
  end

  def children
    AUTHORIZED_RESULT
  end

  def collections_tree_fragment
    AUTHORIZED_RESULT
  end

  def create
    if user
      return AUTHORIZED_RESULT if role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?
      return AUTHORIZED_RESULT if unit != Unit &&
        role >= Role::INSTITUTION_ADMINISTRATOR &&
        user.institution_admin?(user.institution)
    end
    { authorized: false,
      reason:     "You must be an administrator of the institution in which "\
                  "the unit is to reside." }
  end

  def destroy
    if !user
      return LOGGED_OUT_RESULT
    elsif (role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?) ||
      # unit is a child unit and user is primary admin of its root unit.
      # (Note that the unit must also be empty of collections and child
      # units; this is validated in the model.)
      (unit.child? && Role::UNIT_ADMINISTRATOR &&
          user == unit.root_parent.primary_administrator)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason: "You must be a primary administrator of the unit's parent unit." }
  end

  def edit_administrators
    show_access
  end

  def edit_membership
    update
  end

  def edit_properties
    update
  end

  def index
    AUTHORIZED_RESULT
  end

  def item_download_counts
    show_statistics
  end

  def item_results
    show_items
  end

  def new
    create
  end

  def show
    AUTHORIZED_RESULT
  end

  def show_access
    update
  end

  def show_collections
    show
  end

  def show_items
    show
  end

  def show_properties
    show
  end

  def show_statistics
    show
  end

  def show_unit_membership
    show
  end

  def statistics_by_range
    show_statistics
  end

  def update
    if user
      return AUTHORIZED_RESULT if role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?
      return AUTHORIZED_RESULT if unit != Unit &&
        role >= Role::UNIT_ADMINISTRATOR && user.effective_unit_admin?(unit)
    end
    { authorized: false, reason: "You must be an administrator of the unit." }
  end
end
