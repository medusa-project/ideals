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
      return AUTHORIZED_RESULT if role >= Role::INSTITUTION_ADMINISTRATOR &&
        user.institution_admin?(user.institution)
    end
    { authorized: false,
      reason:     "You must be an administrator of the institution in which "\
                  "the unit is to reside." }
  end

  def delete
    # (Note that the unit must also be empty of collections and child
    # units; this is validated in the model.)
    if !user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    elsif (!role || role >= Role::INSTITUTION_ADMINISTRATOR) &&
      user.effective_institution_admin?(unit.institution)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason:     "You must be an administrator of the institution in which "\
                  "this unit resides." }
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

  def export_items
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

  def new_collection
    if !user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    elsif role >= Role::UNIT_ADMINISTRATOR && user.effective_unit_admin?(unit)
      return AUTHORIZED_RESULT
    end
    {
      authorized: false,
      reason: "You must be an administrator of this unit."
    }
  end

  def show
    AUTHORIZED_RESULT
  end

  def show_about
    show
  end

  def show_access
    update
  end

  def show_collections
    show
  end

  def show_extended_about
    effective_admin
  end

  def show_items
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

  def undelete
    delete
  end

  def update
    effective_admin
  end


  private

  def effective_admin
    if !user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    elsif role >= Role::UNIT_ADMINISTRATOR && user.effective_unit_admin?(unit)
      return AUTHORIZED_RESULT
    end
    { authorized: false, reason: "You must be an administrator of the unit." }
  end

end
