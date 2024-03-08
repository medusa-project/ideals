# frozen_string_literal: true

class SubmissionProfileElementPolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This element resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param element [SubmissionProfileElement]
  #
  def initialize(request_context, element)
    super(request_context)
    @element = element
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
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @element.submission_profile.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @element.submission_profile.institution, @role_limit)
  end
end
