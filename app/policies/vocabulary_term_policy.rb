class VocabularyTermPolicy < ApplicationPolicy
  attr_reader :user, :ctx_institution, :role, :term

  ##
  # @param request_context [RequestContext]
  # @param term [VocabularyTerm]
  #
  def initialize(request_context, term)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role            = request_context&.role_limit
    @term            = term
  end

  def create
    effective_institution_admin(user, ctx_institution, role)
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
    result = effective_institution_admin(user, ctx_institution, role)
    result[:authorized] ?
      effective_institution_admin(user, term.vocabulary.institution, role) :
      result
  end
end
