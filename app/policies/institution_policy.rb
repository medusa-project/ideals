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
    effective_sysadmin(user, role)
  end

  def destroy
    create
  end

  def edit
    update
  end

  ##
  # N.B.: this is not a controller method.
  #
  def edit_properties
    effective_sysadmin(user, role)
  end

  def edit_administrators
    edit
  end

  def edit_theme
    edit
  end

  def index
    create
  end

  def item_download_counts
    show_statistics
  end

  def new
    create
  end

  def show
    update
  end

  def show_access
    show
  end

  def show_properties
    show
  end

  def show_statistics
    show
  end

  def show_theme
    show
  end

  def show_users
    show
  end

  def statistics_by_range
    show_statistics
  end

  def update
    effective_institution_admin(user, institution, role)
  end

end
