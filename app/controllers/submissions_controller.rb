# frozen_string_literal: true

##
# Counterpart of {ItemsController} that manages {Item}s during the submission
# process.
#
class SubmissionsController < ApplicationController

  include MetadataSubmission

  before_action :ensure_institution_host, :ensure_logged_in
  before_action :set_item, only: [:complete, :destroy, :edit, :status, :update]
  before_action :authorize_item, only: [:destroy, :update]
  before_action :check_submitting, only: [:complete, :destroy, :edit, :update]
  before_action :check_submitted, only: :status
  before_action :store_location, only: [:edit, :new]

  ##
  # Handles the final submit button in the submission form, completing a
  # submission.
  #
  # Responds to `POST /submissions/:id/complete`.
  #
  def complete
    raise "Item is not in a submitting state." unless @item.submitting?
    begin
      raise "Item has no attached files" if @item.bitstreams.count < 1
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
        RefreshOpensearchJob.perform_later
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
  # Creates a new [Item] upon acceptance of the {new deposit agreement}.
  # After the submission has been created, the user is redirected to {edit}.
  #
  # Responds to `POST /submissions`.
  #
  def create
    collection = Collection.find_by(id: params[:primary_collection_id]) # may be nil
    item       = CreateItemCommand.new(submitter:          current_user,
                                       institution:        current_institution,
                                       primary_collection: collection).execute
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
    ActiveRecord::Base.transaction do # trigger after_commit callbacks
      @item.bury!
    end
  rescue => e
    flash['error'] = "#{e}"
  else
    flash['success'] = "Your submission has been canceled."
  ensure
    redirect_to @item.institution.scope_url, allow_other_host: true
  end

  ##
  # Renders the submission form.
  #
  # Responds to `GET /submissions/:id/edit`
  #
  def edit
    @submission_profile = @item.effective_submission_profile ||
      current_institution.default_submission_profile
    display_edit_toast
  end

  ##
  # Displays the deposit agreement. At the end of the agreement is a submit
  # button that POSTs to {create}.
  #
  # Clients may arrive here from a main menu, or from a
  # {CollectionsController#show show-collection page}.
  #
  # Responds to `GET /submit` and `GET /collections/:collection_id/deposit`.
  #
  def new
    # This will be nil if we are arriving at /submit, but otherwise we will
    # use it to pre-select the collection in the submission form.
    @collection  = Collection.find_by(id: params[:collection_id])
    # These are all submissions in the same collection, or no collection.
    @submissions = current_user.submitted_items.
      where(stage: Item::Stages::SUBMITTING).
      order(:updated_at)
    if @collection
      @submissions = @submissions.
        joins(:collection_item_memberships).
        where("collection_item_memberships.collection_id": @collection.id)
    end
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
      redirect_to item_path(@item)
    end
  end

  def check_submitted
    unless @item.submitted?
      flash['error'] = "This item is not in a submitted state."
      redirect_to item_path(@item)
    end
  end

  ##
  # Displays a toast containing a message about changes in the edit form being
  # saved automatically, but only once. Once it's been displayed, the item ID
  # is stored in a cookie so it won't be displayed again.
  #
  def display_edit_toast
    if cookies[:submission_notices].blank?
      cookies[:submission_notices] = JSON.generate([])
    end
    notices = Set.new(JSON.parse(cookies[:submission_notices]))
    unless notices.include?(@item.id)
      notices << @item.id
      cookies[:submission_notices] = {
        value:   JSON.generate(notices.to_a),
        expires: 1.day.from_now
      }
      toast!(title:   nil,
             message: "Changes are saved automatically. You can leave this "\
                      "page at any time and return to it later.")
    end
  end

  def item_params
    params.require(:item).permit(:submitter_id, :temp_embargo_expires_at,
                                 :temp_embargo_kind, :temp_embargo_reason,
                                 :temp_embargo_type)
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
        embargo = @item.embargoes.build(kind:   @item.temp_embargo_kind || Embargo::Kind::DOWNLOAD,
                                        reason: @item.temp_embargo_reason)
        if @item.temp_embargo_expires_at.present?
          embargo.expires_at = Time.parse(@item.temp_embargo_expires_at)
          embargo.perpetual  = false
        else
          embargo.perpetual = true
        end
        if @item.temp_embargo_type == "institution"
          embargo.user_groups << current_institution.defining_user_group
        end
      end
      @item.temp_embargo_type       = nil
      @item.temp_embargo_kind       = nil
      @item.temp_embargo_expires_at = nil
      @item.temp_embargo_reason     = nil
    end
  end

end