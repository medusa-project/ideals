# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  attr_reader :subject_user, :object_user

  ##
  # @param subject_user [User] The user requesting access.
  # @param object_user [User] The user to which access is being requested.
  #
  def initialize(subject_user, object_user)
    @subject_user = subject_user
    @object_user  = object_user
  end

  def edit?
    update?
  end

  def index?
    subject_user.sysadmin?
  end

  def show?
    subject_user.sysadmin?
  end

  def update?
    subject_user.sysadmin?
  end
end
