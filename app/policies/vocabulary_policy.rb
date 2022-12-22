class VocabularyPolicy < ApplicationPolicy
  attr_reader :user, :ctx_institution, :role, :vocabulary

  ##
  # @param request_context [RequestContext]
  # @param vocabulary [Vocabulary]
  #
  def initialize(request_context, vocabulary)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role            = request_context&.role_limit
    @vocabulary      = vocabulary
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
    result = effective_institution_admin(user, ctx_institution, role)
    result[:authorized] ?
      effective_institution_admin(user, vocabulary.institution, role) :
      result
  end
end
