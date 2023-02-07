class SubmissionProfilesController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_profile, only: [:clone, :edit, :show, :update, :destroy]
  before_action :authorize_profile, only: [:clone, :edit, :show, :update, :destroy]
  before_action :store_location, only: [:index, :show]

  ##
  # Responds to `POST /admin/submission-profiles/:id/clone`
  #
  def clone
    begin
      clone = @profile.dup
      clone.save!
    rescue => e
      flash['error'] = "#{e}"
      redirect_back fallback_location: submission_profile_path(@profile)
    else
      toast!(title:   "Profile cloned",
             message: "The submission profile \"#{@profile.name}\" has been "\
                      "cloned as \"#{clone.name}\".")
      redirect_to submission_profile_path(clone)
    end
  end

  ##
  # Responds to `POST /submission-profiles` (XHR only)
  #
  def create
    @profile             = SubmissionProfile.new(submission_profile_params)
    @profile.institution = current_institution
    authorize @profile
    begin
      @profile.add_default_elements
      @profile.save!
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @profile.errors.any? ? @profile : e },
             status: :bad_request
    else
      toast!(title:   "Profile cloned",
             message: "The submission profile \"#{@profile.name}\" has been "\
                      "created.")
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /submission-profiles/:id`
  #
  def destroy
    begin
      @profile.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      toast!(title:   "Profile deleted",
             message: "The submission profile \"#{@profile.name}\" has been "\
                      "deleted.")
    ensure
      redirect_to submission_profiles_path
    end
  end

  ##
  # Responds to `GET /submission-profiles/:id` (XHR only)
  #
  def edit
    render partial: "submission_profiles/form",
           locals: { profile: @profile }
  end

  ##
  # Responds to `GET /submission-profiles`
  #
  def index
    authorize SubmissionProfile
    institution  = current_institution
    @profiles    = SubmissionProfile.where(institution: institution).order(:name)
    @new_profile = SubmissionProfile.new(institution: institution)
  end

  ##
  # Responds to `GET /submission-profiles/:id`
  #
  def show
    # N.B.: these are only directly-assigned collections. For the default
    # profile, the collections list won't be displayed because it would include
    # almost all of them.
    @collections = @profile.collections
    @new_element = SubmissionProfileElement.new
  end

  ##
  # Responds to `PATCH /submission-profiles/:id` (XHR only)
  #
  def update
    begin
      @profile.update!(submission_profile_params)
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @profile.errors.any? ? @profile : e },
             status: :bad_request
    else
      toast!(title:   "Profile updated",
             message: "The submission profile \"#{@profile.name}\" has been "\
                      "updated.")
      render "shared/reload"
    end
  end

  private

  def submission_profile_params
    params.require(:submission_profile).permit(:institution_default, :name)
  end

  def set_profile
    @profile = SubmissionProfile.find(params[:id] || params[:submission_profile_id])
    @breadcrumbable = @profile
  end

  def authorize_profile
    @profile ? authorize(@profile) : skip_authorization
  end

end
