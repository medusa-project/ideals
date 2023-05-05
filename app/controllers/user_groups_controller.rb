# frozen_string_literal: true

class UserGroupsController < ApplicationController

  before_action :ensure_institution_host, :ensure_logged_in
  before_action :set_user_group, except: [:create, :index, :index_global, :new]
  before_action :authorize_user_group, except: [:create, :index, :index_global,
                                                :new]
  before_action :store_location, only: [:index, :index_global, :show]

  ##
  # Responds to `POST /user-groups` (XHR only)
  #
  def create
    @user_group = UserGroup.new(user_group_params)
    authorize @user_group
    begin
      @user_group.save!
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @user_group.errors.any? ? @user_group : e },
             status: :bad_request
    else
      toast!(title:   "User group created",
             message: "The user group \"#{@user_group.name}\" has been created.")
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /user-groups/:id`
  #
  def destroy
    begin
      @user_group.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      toast!(title:   "User group deleted",
             message: "The user group \"#{@user_group.name}\" has been deleted.")
    ensure
      redirect_to user_groups_path
    end
  end

  ##
  # Responds to `GET /user-groups/:id/edit` (XHR only)
  #
  def edit
    render partial: "user_groups/form",
           locals: { user_group: @user_group }
  end

  ##
  # Responds to `GET /user-groups/:id/edit-ad-groups` (XHR only)
  #
  def edit_ad_groups
    render partial: "user_groups/ad_groups_form",
           locals: { user_group: @user_group }
  end

  ##
  # Responds to `GET /user-groups/:id/edit-affiliations` (XHR only)
  #
  def edit_affiliations
    render partial: "user_groups/affiliations_form",
           locals: { user_group: @user_group }
  end

  ##
  # Responds to `GET /user-groups/:id/edit-departments` (XHR only)
  #
  def edit_departments
    render partial: "user_groups/departments_form",
           locals: { user_group: @user_group }
  end

  ##
  # Responds to `GET /user-groups/:id/edit-email-patterns` (XHR only)
  #
  def edit_email_patterns
    render partial: "user_groups/email_patterns_form",
           locals: { user_group: @user_group }
  end

  ##
  # Responds to `GET /user-groups/:id/edit-hosts` (XHR only)
  #
  def edit_hosts
    render partial: "user_groups/hosts_form",
           locals: { user_group: @user_group }
  end

  ##
  # Responds to `GET /user-groups/:id/edit-users` (XHR only)
  #
  def edit_users
    render partial: "user_groups/users_form",
           locals: { user_group: @user_group }
  end

  ##
  # Renders a list of institution-scoped user groups.
  #
  # Responds to `GET /user-groups`.
  #
  # @see index_global
  #
  def index
    authorize UserGroup
    @user_groups    = UserGroup.where(institution: current_institution).order(:name)
    @new_user_group = UserGroup.new
  end

  ##
  # Renders a list of global user groups.
  #
  # Responds to `GET /global-user-groups`.
  #
  # @see index
  #
  def index_global
    authorize UserGroup
    @user_groups    = UserGroup.where(institution: nil).order(:name)
    @new_user_group = UserGroup.new
  end

  ##
  # Responds to `GET /user-groups/new` (XHR only)
  #
  def new
    render partial: "user_groups/form",
           locals: { user_group: UserGroup.new }
  end

  ##
  # Responds to `GET /user-groups/:id`
  #
  def show
    @users          = @user_group.users.order(:name)
    @ad_groups      = @user_group.ad_groups.order(:name)
    @hosts          = @user_group.hosts.order(:pattern)
    @departments    = @user_group.departments.order(:name)
    @affiliations   = @user_group.affiliations.order(:name)
    @email_patterns = @user_group.email_patterns.order(:pattern)
  end

  ##
  # Responds to `PATCH /user-groups/:id` (XHR only)
  #
  def update
    begin
      UserGroup.transaction do
        # Process input from the various edit modals.
        build_ad_groups
        build_users
        build_hosts
        build_departments
        build_email_patterns
        @user_group.update!(user_group_params)
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @user_group.errors.any? ? @user_group : e },
             status: :bad_request
    else
      toast!(title:   "User group updated",
             message: "The user group \"#{@user_group.name}\" has been updated.")
      render "shared/reload"
    end
  end


  private

  def build_ad_groups
    if params[:user_group][:ad_groups]&.respond_to?(:each)
      @user_group.ad_groups.destroy_all
      params[:user_group][:ad_groups].select(&:present?).each do |name|
        @user_group.ad_groups.build(name: name)
      end
    end
  end

  def build_departments
    if params[:user_group][:departments]&.respond_to?(:each)
      @user_group.departments.destroy_all
      params[:user_group][:departments].select(&:present?).each do |name|
        @user_group.departments.build(name: name)
      end
    end
  end

  def build_email_patterns
    if params[:user_group][:email_patterns]&.respond_to?(:each)
      @user_group.email_patterns.destroy_all
      params[:user_group][:email_patterns].select(&:present?).each do |pattern|
        @user_group.email_patterns.build(pattern: pattern)
      end
    end
  end

  def build_hosts
    if params[:user_group][:hosts]&.respond_to?(:each)
      @user_group.hosts.destroy_all
      params[:user_group][:hosts].select(&:present?).each do |pattern|
        @user_group.hosts.build(pattern: pattern)
      end
    end
  end

  def build_users
    if params[:user_group][:users]&.respond_to?(:each)
      UserGroupUser.
        where(user_group: @user_group).
        destroy_all
      params[:user_group][:users].select(&:present?).each do |user_str|
        user = User.from_autocomplete_string(user_str)
        @user_group.users << user if user
      end
    end
  end

  def user_group_params
    params.require(:user_group).permit(:institution_id, :name,
                                       affiliation_ids: [],
                                       department_ids: [], user_ids: [])
  end

  def set_user_group
    @user_group = UserGroup.find(params[:id] || params[:user_group_id])
    @breadcrumbable = @user_group
  end

  def authorize_user_group
    @user_group ? authorize(@user_group) : skip_authorization
  end

end
