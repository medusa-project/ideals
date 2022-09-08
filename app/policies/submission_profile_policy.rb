class SubmissionProfilePolicy < ApplicationPolicy

  attr_reader :user, :institution, :role, :submission_profile

  ##
  # @param request_context [RequestContext]
  # @param submission_profile [SubmissionProfile]
  #
  def initialize(request_context, submission_profile)
    @user               = request_context&.user
    @institution        = request_context&.institution
    @role               = request_context&.role_limit
    @submission_profile = submission_profile
  end

  def clone
    create
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
