# frozen_string_literal: true

class UnitPolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This unit resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param unit [Unit]
  #
  def initialize(request_context, unit)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role_limit      = request_context&.role_limit || Role::NO_LIMIT
    @unit            = unit
  end

  ##
  # Invoked from {UnitsController#update} to ensure that a user cannot move a
  # unit to another unit of which s/he is not an effective administrator.
  #
  def change_parent(new_parent_id)
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @unit.institution
      return WRONG_SCOPE_RESULT
    elsif new_parent_id == @unit.parent_id
      return AUTHORIZED_RESULT
    elsif effective_unit_admin?
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason:     "You must be an administrator of the desired parent unit." }
  end

  def children
    index
  end

  def collections_tree_fragment
    index
  end

  def create
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @unit == Unit &&
      effective_institution_admin?(@user, @ctx_institution, @role_limit)
      return AUTHORIZED_RESULT
    elsif @unit.kind_of?(Unit) &&
      effective_institution_admin?(@user, @unit.institution, @role_limit)
      return AUTHORIZED_RESULT
    elsif @role_limit >= Role::UNIT_ADMINISTRATOR &&
      @unit.kind_of?(Unit) && @unit.parent && @user.effective_unit_admin?(@unit.parent)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason:     "You must be an administrator of the institution in which "\
                  "the unit resides." }
  end

  def delete
    # (Note that the unit must also be empty of collections and child
    # units; this is validated in the model.)
    create
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
    if @unit.kind_of?(Unit) && @ctx_institution != @unit.institution
      return WRONG_SCOPE_RESULT
    end
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
    effective_unit_admin
  end

  def show
    if effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @unit.institution
      return WRONG_SCOPE_RESULT
    end
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
    effective_unit_admin
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
    effective_unit_admin
  end

  def effective_unit_admin
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @unit.kind_of?(Unit) && @ctx_institution != @unit.institution
      return WRONG_SCOPE_RESULT
    elsif @role_limit >= Role::UNIT_ADMINISTRATOR && @user.effective_unit_admin?(@unit)
      return AUTHORIZED_RESULT
    end
    { authorized: false, reason: "You must be an administrator of the unit." }
  end

end
