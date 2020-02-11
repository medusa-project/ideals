class MetadataProfilesController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_profile, only: [:edit, :show, :update, :destroy]
  before_action :authorize_profile, only: [:edit, :show, :update, :destroy]

  ##
  # Responds to `POST /metadata-profiles` (XHR only)
  #
  def create
    @profile = MetadataProfile.new(metadata_profile_params)
    authorize @profile
    begin
      @profile.save!
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @profile },
             status: :bad_request
    else
      flash['success'] = "Metadata profile \"#{@profile.name}\" created."
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /metadata-profiles/:id`
  #
  def destroy
    begin
      @profile.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      flash['success'] = "Metadata profile \"#{@profile.name}\" deleted."
    ensure
      redirect_back fallback_location: metadata_profiles_path
    end
  end

  ##
  # Responds to `GET /metadata-profiles/:id` (XHR only)
  #
  def edit
    render partial: "metadata_profiles/form",
           locals: { profile: @profile, context: :edit }
  end

  ##
  # Responds to `GET /metadata-profiles`
  #
  def index
    authorize MetadataProfile
    @profiles = MetadataProfile.all.order(:name)
    @new_profile = MetadataProfile.new
  end

  ##
  # Responds to `GET /metadata-profiles/:id`
  #
  def show
    @new_element = MetadataProfileElement.new
  end

  ##
  # Responds to `PATCH /metadata-profiles/:id` (XHR only)
  #
  def update
    begin
      @profile.update!(metadata_profile_params)
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @profile },
             status: :bad_request
    else
      flash['success'] = "Metadata profile \"#{@profile.name}\" updated."
      render "shared/reload" # update.js.erb will reload the page
    end
  end

  private

  def metadata_profile_params
    params.require(:metadata_profile).permit(:default, :name)
  end

  def set_profile
    @profile = MetadataProfile.find(params[:id])
    @breadcrumbable = @profile
  end

  def authorize_profile
    @profile ? authorize(@profile) : skip_authorization
  end

end
