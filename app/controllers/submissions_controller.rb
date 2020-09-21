# frozen_string_literal: true

##
# Counterpart of {ItemsController} that manages {Item}s during the submission
# process.
#
class SubmissionsController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_item, only: [:complete, :destroy, :edit, :update]
  before_action :authorize_item, only: [:destroy, :update]
  before_action :check_submitting, only: [:complete, :destroy, :edit, :update]

  ##
  # Displays the deposit agreement. At the end of the agreement is a submit
  # button that POSTs to {create}.
  #
  # Clients may arrive here from a main menu, or from a
  # {CollectionsController#show show-collection page}.
  #
  # Responds to `GET /deposit` and `GET /collections/:collection_id/deposit`.
  #
  def agreement
    @submissions = current_user.submitted_items.
        where(submitting: true).
        order(:updated_at)
  end

  ##
  # Completes an in-progress submission. The intent is for the submission
  # form's complete-submission button to POST to this via XHR.
  #
  # Responds to `POST /submissions/:id/complete`
  #
  def complete
    unless @resource.submitting
      render plain: "Resource is not in a submitting state.",
             status: :conflict and return
    end
    # This is also validated on the client, but do it here too to be safe.
    unless @resource.required_elements_present?
      render plain: "Item is missing required elements.",
             status: :bad_request and return
    end
    # This is also validated on the client, but do it here too to be safe.
    if @resource.bitstreams.count < 1
      render plain: "Item has no associated bitstreams.",
             status: :bad_request and return
    end
    @resource.assign_handle
    @resource.ingest_into_medusa
    @resource.update!(submitting: false)
  end

  ##
  # Creates a new {Item} upon acceptance of the {agreement deposit agreement}.
  # After the submission has been created, the user is redirected to {edit}.
  #
  # Responds to `POST /submissions`.
  #
  def create
    item = Item.new_for_submission(submitter: current_user,
                                   primary_collection_id: params[:primary_collection_id])
    authorize item, policy_class: SubmissionPolicy # this should always succeed
    redirect_to edit_submission_path(item)
  end

  ##
  # Cancels a submission.
  #
  # Responds to `DELETE /submissions/:id`
  #
  # @see destroy
  #
  def destroy
    begin
      @resource.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Submission canceled."
    ensure
      redirect_to root_path
    end
  end

  ##
  # Renders the submission form.
  #
  # Responds to `GET /submissions/:id/edit`
  #
  def edit
    @submission_profile = @resource.effective_submission_profile
  end

  ##
  # Responds to `PATCH/PUT /submissions/:id`
  #
  def update
    begin
      ActiveRecord::Base.transaction do
        # N.B.: this method does not handle file uploads; see
        # BinariesController.create().
        @resource.update!(item_params)
        build_metadata
        @resource.save!
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @resource.errors.any? ? @resource : e },
             status: :bad_request
    else
      head :no_content
    end
  end

  private

  def authorize_item
    @resource ? authorize(@resource, policy_class: SubmissionPolicy) :
        skip_authorization
  end

  ##
  # Ensures that an {Item} is only operated on when it is {Item#submitting
  # marked as being in the submission process}.
  #
  def check_submitting
    unless @resource.submitting
      flash['error'] = "This item has already been submitted."
      redirect_back fallback_location: root_path
    end
  end

  def item_params
    params.require(:item).permit(:primary_collection_id, :submitter_id)
  end

  def set_item
    @resource = Item.find(params[:id] || params[:submission_id])
  end

  ##
  # Builds and ascribes {AscribedElement}s to the item based on user input.
  # Doing this manually is easier than using Rails nested attributes.
  #
  def build_metadata
    if params[:elements].present?
      ActiveRecord::Base.transaction do
        @resource.elements.destroy_all
        params[:elements].select{ |e| e[:string].present? }.each do |element|
          @resource.elements.build(registered_element: RegisteredElement.find_by_name(element[:name]),
                                   string:             element[:string]).save
        end
      end
    end
  end

end