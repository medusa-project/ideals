class SubmissionProfileElementsController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_element, only: [:edit, :update, :destroy]
  before_action :authorize_element, only: [:edit, :update, :destroy]

  ##
  # Responds to POST /submission-profiles/:submission_profile_id/elements
  # (XHR only)
  #
  def create
    @element = SubmissionProfileElement.new(element_params)
    authorize @element, policy_class: SubmissionProfilePolicy
    begin
      @element.save!
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @element },
             status: :bad_request
    else
      flash['success'] = "Element \"#{@element.label}\" created."
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /submission-profiles/:submission_profile_id/elements/:id`
  #
  def destroy
    begin
      @element.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      flash['success'] = "Element \"#{@element.label}\" deleted."
    ensure
      redirect_back fallback_location: @element.submission_profile
    end
  end

  ##
  # Responds to `GET /submission-profiles/:submission_profile_id/elements/:id`
  # (XHR only)
  #
  def edit
    render partial: "submission_profile_elements/form",
           locals: { profile: @element.submission_profile,
                     element: @element,
                     context: :edit }
  end

  ##
  # Responds to `PATCH /submission-profiles/:submission_profile_id/elements/:id`
  # (XHR only)
  #
  def update
    begin
      @element.update!(element_params)
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @element },
             status: :bad_request
    else
      flash['success'] = "Element \"#{@element.label}\" updated."
      render "shared/reload"
    end
  end

  private

  def element_params
    params.require(:submission_profile_element).permit(:help_text, :index,
                                                       :input_type, :label,
                                                       :placeholder_text,
                                                       :registered_element_id,
                                                       :repeatable, :required,
                                                       :submission_profile_id)
  end

  def set_element
    @element = SubmissionProfileElement.find(params[:id])
  end

  def authorize_element
    @element ?
        authorize(@element, policy_class: SubmissionProfilePolicy) :
        skip_authorization
  end

end
