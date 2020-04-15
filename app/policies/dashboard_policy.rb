# frozen_string_literal: true

class DashboardPolicy < Struct.new(:user, :dashboard)

  ##
  # @param user_context [UserContext]
  # @param noop [Object]
  #
  def initialize(user_context, noop)
    @user       = user_context&.user
    @role       = user_context&.role_limit || Role::NO_LIMIT
  end

  def index?
    @user && @role && @role >= Role::LOGGED_IN
  end

end
