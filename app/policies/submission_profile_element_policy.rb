# frozen_string_literal: true

class SubmissionProfileElementPolicy < ApplicationPolicy

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
    @role_limit      = request_context&.role_limit
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

  def update
    if @ctx_institution != @element.submission_profile.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @element.submission_profile.institution, @role_limit)
  end
end
