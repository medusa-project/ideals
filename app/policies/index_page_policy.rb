# frozen_string_literal: true

class IndexPagePolicy < ApplicationPolicy
  attr_reader :user, :institution, :role, :index_page

  ##
  # @param request_context [RequestContext]
  # @param index_page [IndexPage]
  #
  def initialize(request_context, index_page)
    @user        = request_context&.user
    @institution = request_context&.institution
    @role        = request_context&.role_limit
    @index_page  = index_page
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
    if institution.key == index_page.institution.key
      AUTHORIZED_RESULT
    else
      { authorized: false,
        reason:     "You are not authorized to access this index." }
    end
  end

  def update
    create
  end
end
