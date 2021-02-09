# frozen_string_literal: true

class MetadataProfilePolicy < ApplicationPolicy
  attr_reader :user, :role, :metadata_profile

  ##
  # @param request_context [RequestContext]
  # @param metadata_profile [MetadataProfile]
  #
  def initialize(request_context, metadata_profile)
    @user             = request_context&.user
    @role             = request_context&.role_limit
    @metadata_profile = metadata_profile
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
