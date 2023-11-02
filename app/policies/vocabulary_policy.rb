# frozen_string_literal: true

class VocabularyPolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This vocabulary resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param vocabulary [Vocabulary]
  #
  def initialize(request_context, vocabulary)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role_limit      = request_context&.role_limit || Role::NO_LIMIT
    @vocabulary      = vocabulary
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
    elsif @ctx_institution != @vocabulary.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @vocabulary.institution, @role_limit)
  end
end
