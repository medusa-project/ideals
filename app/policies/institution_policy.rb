# frozen_string_literal: true

class InstitutionPolicy < ApplicationPolicy
  attr_reader :user, :role, :institution

  ##
  # @param request_context [RequestContext]
  # @param institution [Institution]
  #
  def initialize(request_context, institution)
    @user        = request_context&.user
    @role        = request_context&.role_limit
    @institution = institution
  end

  def create
    index
  end

  def destroy
    index
  end

  def edit
    update
  end

  def edit_administrators
    show_access
  end

  def index
    effective_sysadmin(user, role)
  end

  def item_download_counts
    show_statistics
  end

  def new
    create
  end

  def show
    institution_admin
  end

  def show_access
    update
  end

  def show_statistics
    show
  end

  def show_properties
    show
  end

  def show_users
    show
  end

  def statistics_by_range
    show_statistics
  end

  def update
    institution_admin
  end


  private

  def institution_admin
    if (!role || role >= Role::INSTITUTION_ADMINISTRATOR) &&
        user&.effective_institution_admin?(institution)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason: "You must be an administrator of this institution." }
  end

end
