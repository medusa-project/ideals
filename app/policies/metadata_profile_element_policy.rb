# frozen_string_literal: true

class MetadataProfileElementPolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This element resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param element [MetadataProfileElement]
  #
  def initialize(request_context, element)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role_limit      = request_context&.role_limit || Role::NO_LIMIT
    @element         = element
  end

  def create
    effective_institution_admin(@user, @ctx_institution, @role_limit)
  end

  def destroy
    update
  end

  def edit
    update
  end

  def new
    create
  end

  def update
    if @element.metadata_profile.global?
      return effective_sysadmin(@user, @role_limit)
    elsif @ctx_institution != @element.metadata_profile.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @element.metadata_profile.institution, @role_limit)
  end
end
