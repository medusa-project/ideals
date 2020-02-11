class MetadataProfileElementsController < ApplicationController

  before_action :ensure_logged_in
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
  # Responds to `DELETE /metadata-profiles/:metadata_profile_id/elements/:id`
  #
  def destroy
    begin
      @element.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      flash['success'] = "Element \"#{@element.label}\" deleted."
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
                     element: @element,
                     context: :edit }
  end

  ##
  # Responds to `PATCH /metadata-profiles/:metadata_profile_id/elements/:id`
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
    params.require(:metadata_profile_element).permit(:facetable, :index, :label,
                                                     :metadata_profile_id,
                                                     :registered_element_id,
                                                     :repeatable, :required,
                                                     :searchable, :sortable,
                                                     :visible)
  end

  def set_element
    @element = MetadataProfileElement.find(params[:id])
  end

  def authorize_element
    @element ?
        authorize(@element, policy_class: MetadataProfilePolicy) :
        skip_authorization
  end

end
