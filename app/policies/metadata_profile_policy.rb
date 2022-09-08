# frozen_string_literal: true

class MetadataProfilePolicy < ApplicationPolicy
  attr_reader :user, :institution, :role, :metadata_profile

  ##
  # @param request_context [RequestContext]
  # @param metadata_profile [MetadataProfile]
  #
  def initialize(request_context, metadata_profile)
    @user             = request_context&.user
    @institution      = request_context&.institution
    @role             = request_context&.role_limit
    @metadata_profile = metadata_profile
  end

  def clone
    create
  end

  def create
    effective_institution_admin(user, institution, role)
  end

  def destroy
    create
  end

  def edit
    update
  end

  def index
    create
  end

  def new
    create
  end

  def show
    index
  end

  def update
    create
  end
end
