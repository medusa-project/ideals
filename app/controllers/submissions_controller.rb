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
        where(stage: Item::Stages::SUBMITTING).
        order(:updated_at)
  end

  ##
  # Completes an in-progress submission. The intent is for the submission
  # form's complete-submission button to POST to this via XHR.
  #
  # Responds to `POST /submissions/:id/complete`
  #
  def complete
    raise "Item is not in a submitting state." unless @item.submitting?
    UpdateItemCommand.new(item:        @item,
                          user:        current_user,
                          description: "Completed the submission process.").execute do
      @item.complete_submission
      @item.save!
    end
  rescue ActiveRecord::RecordInvalid => e
    render plain: "#{e}", status: :bad_request
  rescue => e
    render plain: "#{e}", status: :conflict
  end

  ##
  # Creates a new {Item} upon acceptance of the {agreement deposit agreement}.
  # After the submission has been created, the user is redirected to {edit}.
  #
  # Responds to `POST /submissions`.
  #
  def create
    command = CreateItemCommand.new(submitter: current_user)
    item    = command.execute
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
      @item.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Your submission has been canceled."
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
    @submission_profile = @item.effective_submission_profile
  end

  ##
  # Responds to `PATCH/PUT /submissions/:id`
  #
  def update
    begin
      ActiveRecord::Base.transaction do
        # N.B. 1: this method does not handle file uploads; see
        # BinariesController.create().
        # N.B. 2: this is not done via UpdateItemCommand because there is no
        # need to record an event for every edit of a submission-in-progress.
        @item.update!(item_params)
        if params[:item][:primary_collection_id]
          @item.primary_collection =
            Collection.find(params[:item][:primary_collection_id])
        end
        build_metadata
        @item.save!
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @item.errors.any? ? @item : e },
             status: :bad_request
    else
      head :no_content
    end
  end

  private

  def authorize_item
    @item ? authorize(@item, policy_class: SubmissionPolicy) :
        skip_authorization
  end

  ##
  # Ensures that an {Item} is only operated on when it is in the
  # {Item::Stages::SUBMITTING submission process}.
  #
  def check_submitting
    unless @item.submitting?
      flash['error'] = "This item has already been submitted."
      redirect_back fallback_location: root_path
    end
  end

  def item_params
    params.require(:item).permit(:submitter_id)
  end

  def set_item
    @item = Item.find(params[:id] || params[:submission_id])
  end

  ##
  # Builds and ascribes {AscribedElement}s to the item based on user input.
  # Doing this manually is easier than using Rails nested attributes.
  #
  def build_metadata
    if params[:elements].present?
      ActiveRecord::Base.transaction do
        @item.elements.destroy_all
        params[:elements].select{ |e| e[:string].present? }.each do |element|
          @item.elements.build(registered_element: RegisteredElement.find_by_name(element[:name]),
                               string:             element[:string]).save
        end
      end
    end
  end

end