# frozen_string_literal: true

##
# N.B.: To use this policy, a {LocalUser} or {ShibbolethUser} instance must be
# cast to its {User} superclass; for example:
#
# ```
# authorize(user.becomes(User))
# policy(user.becomes(User)).edit?
# ```
#
class UserPolicy < ApplicationPolicy
  attr_reader :subject_user, :role, :object_user

  ##
  # @param request_context [RequestContext]
  # @param object_user [User] The user to which access is being requested.
  #
  def initialize(request_context, object_user)
    @subject_user = request_context&.user
    @role         = request_context&.role_limit
    @object_user  = object_user
  end

  def edit_properties
    sysadmin_or_same_user
  end

  def index
    effective_sysadmin(subject_user, role)
  end

  ##
  # This does not correspond to a controller method.
  #
  def invite
    effective_sysadmin(subject_user, role)
  end

  def show
    sysadmin_or_same_user
  end

  def show_privileges
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
    sysadmin_or_same_user
  end


  private

  def sysadmin_or_same_user
    if subject_user
      return AUTHORIZED_RESULT if (role >= Role::LOGGED_IN && subject_user.id == object_user.id) ||
        effective_sysadmin?(subject_user, role)
    end
    { authorized: false,
      reason:     "You don't have permission to edit this user account." }
  end

end
