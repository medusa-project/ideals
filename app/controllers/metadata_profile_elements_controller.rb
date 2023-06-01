# frozen_string_literal: true

class MetadataProfileElementsController < ApplicationController

  before_action :ensure_institution_host, :ensure_logged_in
  before_action :set_element, only: [:edit, :update, :destroy]
  before_action :authorize_element, only: [:edit, :update, :destroy]

  ##
  # Responds to POST /metadata-profiles/:metadata_profile_id/elements XHR only)
  #
  def create
    @element = MetadataProfileElement.new(element_params)
    authorize @element, policy_class: MetadataProfilePolicy
    begin
      @element.save!
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @element.errors.any? ? @element : e },
             status: :bad_request
    else
      toast!(title:   "Element created",
             message: "A \"#{@element.label}\" element has been created.")
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /metadata-profiles/:metadata_profile_id/elements/:id`
  #
  def destroy
    begin
      @element.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      toast!(title:   "Element deleted",
             message: "The \"#{@element.label}\" element has been deleted.")
    ensure
      redirect_back fallback_location: @element.metadata_profile
    end
  end

  ##
  # Responds to `GET /metadata-profiles/:metadata_profile_id/elements/:id`
  # (XHR only)
  #
  def edit
    render partial: "metadata_profile_elements/form",
           locals: { profile: @element.metadata_profile,
                     element: @element }
  end

  ##
  # Responds to `GET /metadata-profiles/:metadata_profile_id/elements/new`
  #
  def new
    authorize(MetadataProfileElement)
    @profile = MetadataProfile.find(params[:metadata_profile_id])
    @element = @profile.elements.build
    render partial: "form", locals: { profile: @profile, element: @element }
  end

  ##
  # Responds to `PATCH /metadata-profiles/:metadata_profile_id/elements/:id`
  # (XHR only)
  #
  def update
    begin
      @element.update!(element_params)
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @element.errors.any? ? @element : e },
             status: :bad_request
    else
      toast!(title:   "Element updated",
             message: "The \"#{@element.label}\" element has been updated.")
      render "shared/reload"
    end
  end

  private

  def element_params
    params.require(:metadata_profile_element).permit(:faceted,
                                                     :metadata_profile_id,
                                                     :position,
                                                     :registered_element_id,
                                                     :relevance_weight,
                                                     :searchable, :sortable,
                                                     :visible)
  end

  def set_element
    @element = MetadataProfileElement.find(params[:id])
  end

  def authorize_element
    @element ? authorize(@element) : skip_authorization
  end

end
