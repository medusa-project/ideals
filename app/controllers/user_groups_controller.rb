class UserGroupsController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_user_group, except: [:create, :index]
  before_action :authorize_user_group, except: [:create, :index]

  ##
  # Responds to `POST /user-groups` (XHR only)
  #
  def create
    @user_group = UserGroup.new(user_group_params)
    authorize @user_group
    begin
      @user_group.save!
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @user_group },
             status: :bad_request
    else
      flash['success'] = "User group \"#{@user_group.name}\" created."
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
      flash['success'] = "User group \"#{@user_group.name}\" deleted."
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
  # Responds to `GET /user-groups/:id/edit-hosts` (XHR only)
  #
  def edit_hosts
    render partial: "user_groups/hosts_form",
           locals: { user_group: @user_group }
  end

  ##
  # Responds to `GET /user-groups/:id/edit-local-users` (XHR only)
  #
  def edit_local_users
    render partial: "user_groups/local_users_form",
           locals: { user_group: @user_group }
  end

  ##
  # Responds to `GET /user-groups`
  #
  def index
    authorize UserGroup
    @user_groups    = UserGroup.all.order(:name)
    @new_user_group = UserGroup.new
  end

  ##
  # Responds to `GET /user-groups/:id`
  #
  def show
    @users       = @user_group.users.order(:name)
    @ldap_groups = @user_group.ldap_groups.order(:urn)
    @hosts       = @user_group.hosts.order(:pattern)
  end

  ##
  # Responds to `PATCH /user-groups/:id` (XHR only)
  #
  def update
    begin
      UserGroup.transaction do
        # Hosts require manual processing.
        if params[:user_group][:hosts]&.respond_to?(:each)
          @user_group.hosts.destroy_all
          params[:user_group][:hosts].select(&:present?).each do |pattern|
            @user_group.hosts.build(pattern: pattern)
          end
        end
        @user_group.update!(user_group_params)
      end
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @user_group },
             status: :bad_request
    else
      flash['success'] = "User group \"#{@user_group.name}\" updated."
      render "shared/reload"
    end
  end

  private

  def user_group_params
    params.require(:user_group).permit(:key, :name, ldap_group_ids: [],
                                       user_ids: [])
  end

  def set_user_group
    @user_group = UserGroup.find(params[:id] || params[:user_group_id])
    @breadcrumbable = @user_group
  end

  def authorize_user_group
    @user_group ? authorize(@user_group) : skip_authorization
  end

end
