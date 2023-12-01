# frozen_string_literal: true

class SubmissionProfilePolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This submission profile resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param submission_profile [SubmissionProfile]
  #
  def initialize(request_context, submission_profile)
    super(request_context)
    @profile = submission_profile
  end

  def clone
    if effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif !@user
      return LOGGED_OUT_RESULT
    elsif @ctx_institution != @profile.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @profile.institution, @role_limit)
  end

  def create
    if !@user
      return LOGGED_OUT_RESULT
    end
    effective_institution_admin(@user, @ctx_institution, @role_limit)
  end

  def destroy
    update
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
    update
  end

  def update
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @profile.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @profile.institution, @role_limit)
  end
end
