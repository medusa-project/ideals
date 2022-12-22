class SubmissionProfilePolicy < ApplicationPolicy

  attr_reader :user, :ctx_institution, :role, :submission_profile

  ##
  # @param request_context [RequestContext]
  # @param submission_profile [SubmissionProfile]
  #
  def initialize(request_context, submission_profile)
    @user               = request_context&.user
    @ctx_institution    = request_context&.institution
    @role               = request_context&.role_limit
    @submission_profile = submission_profile
  end

  def clone
    destroy
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
      effective_institution_admin(user, submission_profile.institution, role) :
      result
  end
end
