# frozen_string_literal: true

class SubmissionProfilesController < ApplicationController

  before_action :ensure_institution_host, :ensure_logged_in
  before_action :set_profile, except: [:create, :index, :new]
  before_action :authorize_profile, except: [:create, :index]
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
    @profile = SubmissionProfile.new(submission_profile_params)
    authorize @profile
    begin
      if params[:elements].respond_to?(:each)
        params[:elements].each_with_index do |element_id, index|
          @profile.elements.build(registered_element_id: element_id,
                                  position:              index,
                                  repeatable:            false,
                                  required:              true)
        end
      end
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
    institution = @profile.institution
    begin
      if @profile.institution_default
        raise "The default metadata profile cannot be deleted. Set a "\
                "different profile as the default and try again."
      end
      @profile.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      toast!(title:   "Profile deleted",
             message: "The submission profile \"#{@profile.name}\" has been "\
                      "deleted.")
    ensure
      if current_user_is_sysadmin?
        redirect_to institution_path(institution)
      else
        redirect_to submission_profiles_path
      end
    end
  end

  ##
  # Responds to `GET /submission-profiles/:id/edit` (XHR only)
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
    @profiles = SubmissionProfile.
      where(institution: current_institution).
      order(:name)
  end

  ##
  # Responds to `GET /submission-profiles/new`
  #
  # The following query arguments are accepted:
  #
  # * `institution_id`: ID of the owning institution.
  #
  def new
    authorize SubmissionProfile
    if params.dig(:submission_profile, :institution_id).blank?
      render plain: "Missing institution ID", status: :bad_request
      return
    end
    @profile = SubmissionProfile.new(submission_profile_params)
    render partial: "form"
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
    params.require(:submission_profile).permit(:institution_default,
                                               :institution_id, :name)
  end

  def set_profile
    @profile = SubmissionProfile.find(params[:id] || params[:submission_profile_id])
    @breadcrumbable = @profile
  end

  def authorize_profile
    @profile ? authorize(@profile) : skip_authorization
  end

end
