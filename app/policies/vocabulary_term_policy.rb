# frozen_string_literal: true

class VocabularyTermPolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This vocabulary term resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param term [VocabularyTerm]
  #
  def initialize(request_context, term)
    super(request_context)
    @term = term
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

  def import
    create
  end

  def new
    create
  end

  def update
    if @ctx_institution != @term.vocabulary.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @term.vocabulary.institution, @role_limit)
  end
end
