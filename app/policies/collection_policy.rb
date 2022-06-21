# frozen_string_literal: true

class CollectionPolicy < ApplicationPolicy
  attr_reader :user, :role, :collection

  ##
  # @param request_context [RequestContext]
  # @param collection [Collection]
  #
  def initialize(request_context, collection)
    @user       = request_context&.user
    @role       = request_context&.role_limit || Role::NO_LIMIT
    @collection = collection
  end

  ##
  # Invoked from {CollectionsController#update} to ensure that a user cannot
  # move a collection to another collection of which s/he is not an effective
  # manager.
  #
  def change_parent(new_parent_id)
    if !user
      return LOGGED_OUT_RESULT
    elsif new_parent_id == collection.parent_id # no change
      return AUTHORIZED_RESULT
    elsif effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    elsif role >= Role::COLLECTION_MANAGER &&
        user.effective_manager?(Collection.find(new_parent_id))
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason: "You must be a manager of the desired collection in order to "\
              "move it into that collection." }
  end

  def children
    AUTHORIZED_RESULT
  end

  def create
    effective_manager
  end

  def delete
    if !user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    elsif (!role || role >= Role::INSTITUTION_ADMINISTRATOR) &&
      user.effective_institution_admin?(collection.institution)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason:     "You must be an administrator of the institution in which "\
                  "the collection resides." }
  end

  def edit_collection_membership
    update
  end

  def edit_managers
    update
  end

  def edit_properties
    update
  end

  def edit_submitters
    update
  end

  def edit_unit_membership
    update
  end

  def export_items
    effective_manager
  end

  def index
    AUTHORIZED_RESULT
  end

  def item_download_counts
    show_statistics
  end

  def item_results
    show_items
  end

  def new
    create
  end

  def show
    AUTHORIZED_RESULT
  end

  def show_about
    show
  end

  def show_access
    update
  end

  def show_extended_about
    effective_manager
  end

  def show_items
    show
  end

  def show_review_submissions
    effective_manager
  end

  def show_statistics
    show
  end

  def statistics_by_range
    show_statistics
  end

  ##
  # N.B.: this method doesn't correspond to a controller method.
  #
  def submit_item
    effective_submitter
  end

  def undelete
    delete
  end

  def update
    create
  end


  private

  def effective_manager
    if !user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    elsif role >= Role::COLLECTION_MANAGER && collection.is_a?(Collection) &&
        user.effective_manager?(collection)
      return AUTHORIZED_RESULT
    end
    { authorized: false, reason: "You must be a manager of the collection." }
  end

  def effective_submitter
    if !user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    elsif role >= Role::COLLECTION_SUBMITTER && user.effective_submitter?(collection)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason: "You must be authorized to submit to the collection." }
  end

end
