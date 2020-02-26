# frozen_string_literal: true

class SubmissionProfilePolicy < ApplicationPolicy
  attr_reader :user, :submission_profile

  ##
  # @param user [User]
  # @param submission_profile [SubmissionProfile]
  #
  def initialize(user, submission_profile)
    @user               = user
    @submission_profile = submission_profile
  end

  def clone?
    create?
  end

  def create?
    user.sysadmin?
  end

  def destroy?
    create?
  end

  def edit?
    update?
  end

  def index?
    user.sysadmin?
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
