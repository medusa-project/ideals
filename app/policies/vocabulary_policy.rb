class VocabularyPolicy < ApplicationPolicy
  attr_reader :user, :institution, :role, :vocabulary

  ##
  # @param request_context [RequestContext]
  # @param vocabulary [Vocabulary]
  #
  def initialize(request_context, vocabulary)
    @user        = request_context&.user
    @institution = request_context&.institution
    @role        = request_context&.role_limit
    @vocabulary  = vocabulary
  end

  def create
    effective_institution_admin(user, institution, role)
  end

  def destroy
    create
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
    index
  end

  def update
    create
  end
end
