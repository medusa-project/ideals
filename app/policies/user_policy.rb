# frozen_string_literal: true

##
# N.B.: To use this policy, an {IdentityUser} or {ShibbolethUser} instance must
# be cast to its {User} superclass; for example:
#
# ```
# authorize(user.becomes(User))
# policy(user.becomes(User)).edit?
# ```
#
class UserPolicy < ApplicationPolicy
  attr_reader :subject_user, :role, :object_user

  ##
  # @param user_context [UserContext]
  # @param object_user [User] The user to which access is being requested.
  #
  def initialize(user_context, object_user)
    @subject_user = user_context&.user
    @role         = user_context&.role_limit
    @object_user  = object_user
  end

  def edit?
    update?
  end

  def index?
    update?
  end

  def show?
    update?
  end

  def update?
    if subject_user
      return true if role >= Role::SYSTEM_ADMINISTRATOR && subject_user.sysadmin?
    end
    false
  end
end
