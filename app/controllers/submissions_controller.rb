# frozen_string_literal: true

##
# Counterpart of {ItemsController} that manages {Item}s during the submission
# workflow.
#
class SubmissionsController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_item, only: [:destroy, :edit, :update]
  before_action :authorize_item, only: [:destroy, :update]

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
  # Creates a new {Item} upon acceptance of the {deposit deposit agreement}.
  # After the submission has been created, the user is redirected to {edit}.
  #
  # Responds to `POST /items`.
  #
  def create
    item = Item.create!(submitter: current_user,
                        primary_collection_id: params[:collection_id],
                        submitting: true)
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
  # Renders the new-submission form.
  #
  # Responds to `GET /submissions/:id/edit`
  #
  def edit
    @submission_profile = SubmissionProfile.default # TODO: collection-specific
  end

  ##
  # Responds to `PATCH/PUT /items/:id`
  #
  def update
    begin
      ActiveRecord::Base.transaction do
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

  def item_params
    params.require(:item).permit(:primary_collection_id, :submitter_id,
                                 :submitting)
  end

  def set_item
    @resource = Item.find(params[:id])
  end

  ##
  # Builds and ascribes {AscribedElement}s to the item based on user input.
  # This is done manually because to do it using Rails nested attributes would
  # be harder.
  #
  def build_metadata
    if params[:elements].present?
      ActiveRecord::Base.transaction do
        @resource.elements.destroy_all
        params[:elements].select{ |e| e[:string].present? }.each do |element|
          @resource.elements.build(registered_element: RegisteredElement.find_by_name(element[:name]),
                                   string:             element[:string])
        end
      end
    end
  end

end