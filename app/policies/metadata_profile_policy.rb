# frozen_string_literal: true

class MetadataProfilePolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This metadata profile resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param metadata_profile [MetadataProfile]
  #
  def initialize(request_context, metadata_profile)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role_limit      = request_context&.role_limit
    @profile         = metadata_profile
  end

  def clone
    if @profile.global?
      return { authorized: false,
               reason:     "The global metadata profile cannot be cloned." }
    elsif @ctx_institution != @profile.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @profile.institution, @role_limit)
  end

  def create
    effective_institution_admin(@user, @ctx_institution, @role_limit)
  end

  def destroy
    if @profile.global?
      return { authorized: false,
               reason:     "The global metadata profile cannot be deleted." }
    elsif @ctx_institution != @profile.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @profile.institution, @role_limit)
  end

  def edit
    update
  end

  def index
    effective_institution_admin(@user, @ctx_institution, @role_limit)
  end

  def new
    create
  end

  def show
    update
  end

  def update
    if !@user
      return LOGGED_OUT_RESULT
    elsif @profile.global?
      return effective_sysadmin(@user, @role_limit)
    elsif @ctx_institution != @profile.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @profile.institution, @role_limit)
  end
end
