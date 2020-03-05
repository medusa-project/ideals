# frozen_string_literal: true

class SubmissionPolicy < ApplicationPolicy
  attr_reader :user, :submission

  ##
  # @param user [User]
  # @param submission [Submission]
  #
  def initialize(user, submission)
    @user       = user
    @submission = submission
  end

  def create?
    !user.nil?
  end

  def deposit?
    !user.nil?
  end

  def destroy?
    update?
  end

  def edit?
    update?
  end

  def update?
    # user must be logged in
    if user
      # sysadmins can do anything
      return true if user.sysadmin?
      # all users can delete their own submissions
      return true if user == submission.user
      if submission.collection
        # collection managers can delete submissions within their collections
        return true if user.manager?(submission.collection)
        # unit admins can delete submissions within their units
        submission.collection.all_units.each do |unit|
          return true if user.unit_admin?(unit)
        end
      end
    end
    false
  end

end
