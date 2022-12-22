# frozen_string_literal: true

class SubmissionProfileElementPolicy < ApplicationPolicy
  attr_reader :user, :ctx_institution, :role, :element

  ##
  # @param request_context [RequestContext]
  # @param element [MetadataProfileElement]
  #
  def initialize(request_context, element)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role            = request_context&.role_limit
    @element         = element
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

  def update
    result = effective_institution_admin(user, ctx_institution, role)
    result[:authorized] ?
      effective_institution_admin(user, element.submission_profile.institution, role) :
      result
  end
end
