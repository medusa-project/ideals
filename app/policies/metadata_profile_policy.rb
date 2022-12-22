# frozen_string_literal: true

class MetadataProfilePolicy < ApplicationPolicy
  attr_reader :user, :ctx_institution, :role, :metadata_profile

  ##
  # @param request_context [RequestContext]
  # @param metadata_profile [MetadataProfile]
  #
  def initialize(request_context, metadata_profile)
    @user             = request_context&.user
    @ctx_institution  = request_context&.institution
    @role             = request_context&.role_limit
    @metadata_profile = metadata_profile
  end

  def clone
    if metadata_profile.global?
      return { authorized: false,
               reason:     "The global metadata profile cannot be cloned." }
    end
    result = effective_institution_admin(user, ctx_institution, role)
    result[:authorized] ?
      effective_institution_admin(user, metadata_profile.institution, role) :
      result
  end

  def create
    effective_institution_admin(user, ctx_institution, role)
  end

  def destroy
    if metadata_profile.global?
      return { authorized: false,
               reason:     "The global metadata profile cannot be deleted." }
    end
    result = effective_institution_admin(user, ctx_institution, role)
    result[:authorized] ?
      effective_institution_admin(user, metadata_profile.institution, role) :
      result
  end

  def edit
    update
  end

  def index
    effective_institution_admin(user, ctx_institution, role)
  end

  def new
    create
  end

  def show
    update
  end

  def update
    if metadata_profile.global?
      return effective_sysadmin(user, role)
    end
    result = effective_institution_admin(user, ctx_institution, role)
    result[:authorized] ?
      effective_institution_admin(user, metadata_profile.institution, role) :
      result
  end
end
