# frozen_string_literal: true

class MetadataProfilePolicy < ApplicationPolicy
  attr_reader :user, :metadata_profile

  ##
  # @param user [User]
  # @param metadata_profile [MetadataProfile]
  #
  def initialize(user, metadata_profile)
    @user             = user
    @metadata_profile = metadata_profile
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
