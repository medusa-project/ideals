# frozen_string_literal: true

##
# Counterpart of {ItemsController} that manages {Item}s during the submission
# process.
#
class SubmissionsController < ApplicationController

  include MetadataSubmission

  before_action :ensure_logged_in
  before_action :set_item, only: [:complete, :destroy, :edit, :status, :update]
  before_action :authorize_item, only: [:destroy, :update]
  before_action :check_submitting, only: [:complete, :destroy, :edit, :update]
  before_action :check_submitted, only: :status

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
  # Handles the final submit button in the submission form, completing a
  # submission.
  #
  # Responds to `POST /submissions/:id/complete`.
  #
  def complete
    raise "Item is not in a submitting state." unless @item.submitting?
    begin
      # Normally at the end of the updating process, UpdateItemCommand would
      # add an event of Type::UPDATE with a `before_changes` property
      # containing the current (as in, at this very point) state of the item.
      # But several changes have been made to the item through the submission
      # form, outside of any other UpdateItemCommands, since it was created.
      # So we provide the item's state immediately after the last create event
      # in order to capture those.
      after_create_state = @item.events.
        where(event_type: Event::Type::CREATE).
        limit(1).
        first&.
        after_changes
      UpdateItemCommand.new(item:           @item,
                            user:           current_user,
                            description:    "Completed the submission process.",
                            before_changes: after_create_state).execute do
        build_embargo
        @item.complete_submission
        @item.save!
      end
    rescue => e
      flash['error'] = "#{e}"
      redirect_to edit_submission_path(@item)
    else
      if @item.primary_collection&.submissions_reviewed
        redirect_to submission_status_path(@item)
      else
        flash['success'] = "Your submission is complete! "\
                           "Your submitted item appears below."
        redirect_to @item
      end
    end
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
  # Displays the status of a submission that is awaiting approval. Users are
  # redirected here following a submission into a collection that requires
  # approval for submitted items. For all other items, users are redirected
  # directly to the item and never arrive here.
  #
  # Responds to `GET /submissions/:id/status`.
  #
  def status
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
        build_metadata(@item) # MetadataSubmission concern
        @item.save!
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals:  { object: @item.errors.any? ? @item : e },
             status:  :bad_request
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

  def check_submitted
    unless @item.submitted?
      flash['error'] = "This item is not in a submitted state."
      redirect_back fallback_location: root_path
    end
  end

  def item_params
    params.require(:item).permit(:submitter_id, :temp_embargo_type,
                                 :temp_embargo_expires_at,
                                 :temp_embargo_reason)
  end

  def set_item
    @item = Item.find(params[:id] || params[:submission_id])
  end

  ##
  # Builds and ascribes an [Embargo] to the item based on user input.
  #
  def build_embargo
    ActiveRecord::Base.transaction do
      @item.embargoes.destroy_all
      if @item.temp_embargo_type.present? && @item.temp_embargo_type != "open"
        embargo = @item.embargoes.build(kind:        Embargo::Kind::ALL_ACCESS,
                                        expires_at:  Time.parse(@item.temp_embargo_expires_at),
                                        reason:      @item.temp_embargo_reason)
        if @item.temp_embargo_type == "uofi"
          embargo.user_groups << UserGroup.find_by_key("uiuc")
        end

        @item.temp_embargo_type       = nil
        @item.temp_embargo_expires_at = nil
        @item.temp_embargo_reason     = nil
      end
    end
  end

end