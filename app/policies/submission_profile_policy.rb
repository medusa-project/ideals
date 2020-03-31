# frozen_string_literal: true

class SubmissionProfilePolicy < ApplicationPolicy
  attr_reader :user, :role, :submission_profile

  ##
  # @param user_context [UserContext]
  # @param submission_profile [SubmissionProfile]
  #
  def initialize(user_context, submission_profile)
    @user               = user_context&.user
    @role               = user_context&.role_limit
    @submission_profile = submission_profile
  end

  def clone?
    create?
  end

  def create?
    if user
      return true if role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?
    end
    false
  end

  def destroy?
    create?
  end

  def edit?
    update?
  end

  def index?
    create?
  end

  def new?
    create?
  end

  def show?
    index?
  end

  def update?
    create?
  end
end
