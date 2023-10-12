# frozen_string_literal: true

class UserPolicy < ApplicationPolicy

  ##
  # @param request_context [RequestContext]
  # @param object_user [User] The user to which access is being requested.
  #
  def initialize(request_context, object_user)
    @subject_user    = request_context&.user
    @role_limit      = request_context&.role_limit || Role::NO_LIMIT
    @ctx_institution = request_context&.institution
    @object_user     = object_user
  end

  ##
  # N.B. this does not correspond to a controller method.
  #
  def change_institution
    effective_sysadmin(@subject_user, @role_limit)
  end

  def edit_properties
    institution_admin_or_same_user
  end

  def enable
    effective_institution_admin(@subject_user, @ctx_institution, @role_limit)
  end

  def disable
    enable
  end

  def index
    effective_institution_admin(@subject_user, @ctx_institution, @role_limit)
  end

  def index_all
    effective_sysadmin(@subject_user, @role_limit)
  end

  ##
  # This does not correspond to a controller method.
  #
  def invite
    effective_institution_admin(@subject_user, @subject_user&.institution, @role_limit)
  end

  def show
    institution_admin_or_same_user
  end

  def show_credentials
    institution_admin_or_same_user
  end

  def show_logins
    show
  end

  def show_properties
    show
  end

  def show_submittable_collections
    show
  end

  def show_submitted_items
    show
  end

  def show_submissions_in_progress
    show
  end

  def submitted_item_results
    show_submitted_items
  end

  def update_properties
    institution_admin_or_same_user
  end


  private

  def institution_admin_or_same_user
    if @subject_user
      if (@role_limit >= Role::LOGGED_IN && @subject_user.id == @object_user.id) ||
        effective_sysadmin?(@subject_user, @role_limit) ||
        effective_institution_admin?(@subject_user, @object_user.institution, @role_limit)
        return AUTHORIZED_RESULT
      end
    end
    { authorized: false,
      reason:     "You don't have permission to access this user account." }
  end

end
