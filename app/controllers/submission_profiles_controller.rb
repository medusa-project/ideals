class SubmissionProfilesController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_profile, only: [:clone, :edit, :show, :update, :destroy]
  before_action :authorize_profile, only: [:clone, :edit, :show, :update, :destroy]

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
      flash['success'] = "Cloned #{@profile.name} as \"#{clone.name}\"."
      redirect_to submission_profile_path(clone)
    end
  end

  ##
  # Responds to `POST /submission-profiles` (XHR only)
  #
  def create
    @profile = SubmissionProfile.new(submission_profile_params)
    authorize @profile
    begin
      @profile.save!
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @profile },
             status: :bad_request
    else
      flash['success'] = "Submission profile \"#{@profile.name}\" created."
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
      flash['success'] = "Submission profile \"#{@profile.name}\" deleted."
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
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @profile },
             status: :bad_request
    else
      flash['success'] = "Submission profile \"#{@profile.name}\" updated."
      render "shared/reload"
    end
  end

  private

  def submission_profile_params
    params.require(:submission_profile).permit(:default, :institution_id, :name)
  end

  def set_profile
    @profile = SubmissionProfile.find(params[:id] || params[:submission_profile_id])
    @breadcrumbable = @profile
  end

  def authorize_profile
    @profile ? authorize(@profile) : skip_authorization
  end

end
