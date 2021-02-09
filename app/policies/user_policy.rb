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

  def edit_privileges?
    sysadmin?
  end

  def edit_properties?
    self_or_sysadmin?
  end

  def index?
    sysadmin?
  end

  ##
  # This does not correspond to a controller method.
  #
  def invite?
    sysadmin?
  end

  def show?
    self_or_sysadmin?
  end

  def update_privileges?
    sysadmin?
  end

  def update_properties?
    self_or_sysadmin?
  end

  private

  def self_or_sysadmin?
    if subject_user
      return (role >= Role::LOGGED_IN && subject_user.id == object_user.id) ||
          (role >= Role::SYSTEM_ADMINISTRATOR && subject_user.sysadmin?)
    end
    false
  end

  def sysadmin?
    if subject_user
      return role >= Role::SYSTEM_ADMINISTRATOR && subject_user.sysadmin?
    end
    false
  end

end
