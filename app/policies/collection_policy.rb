# frozen_string_literal: true

class CollectionPolicy < ApplicationPolicy

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This collection resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param collection [Collection]
  #
  def initialize(request_context, collection)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role_limit      = request_context&.role_limit || Role::NO_LIMIT
    @collection      = collection
  end

  def all_files
    export_items
  end

  ##
  # Invoked from {CollectionsController#update} to ensure that a user cannot
  # move a collection to another collection of which s/he is not an effective
  # administrator.
  #
  def change_parent(new_parent_id)
    if effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @collection.institution
      return WRONG_SCOPE_RESULT
    elsif !@user
      return LOGGED_OUT_RESULT
    elsif new_parent_id == @collection.parent_id # no change
      return AUTHORIZED_RESULT
    elsif @role_limit >= Role::COLLECTION_ADMINISTRATOR &&
      @user.effective_collection_admin?(Collection.find(new_parent_id))
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason: "You must be an administrator of the desired collection in "\
              "order to move it into that collection." }
  end

  def children
    index
  end

  def create
    effective_admin
  end

  def delete
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @collection.institution
      return WRONG_SCOPE_RESULT
    elsif (!@role_limit || @role_limit >= Role::INSTITUTION_ADMINISTRATOR) &&
      @user.effective_institution_admin?(@collection.institution)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason:     "You must be an administrator of the institution in which "\
                  "the collection resides." }
  end

  def edit_collection_membership
    update
  end

  def edit_administrators
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
    effective_admin
  end

  def index
    if @collection.kind_of?(Collection) &&
      @ctx_institution != @collection.institution
      return WRONG_SCOPE_RESULT
    end
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
    if effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @collection.institution
      return WRONG_SCOPE_RESULT
    end
    AUTHORIZED_RESULT
  end

  def show_about
    show
  end

  def show_access
    update
  end

  def show_extended_about
    effective_admin
  end

  def show_items
    show
  end

  def show_review_submissions
    effective_admin
  end

  def show_statistics
    show
  end

  def show_submissions_in_progress
    show_review_submissions
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

  def effective_admin
    if effective_sysadmin?(@user, @role_limit) ||
      effective_institution_admin?(@user, @ctx_institution, @role_limit)
      return AUTHORIZED_RESULT
    elsif !@user
      return LOGGED_OUT_RESULT
    elsif @collection.kind_of?(Collection) &&
      @ctx_institution != @collection.institution
      return WRONG_SCOPE_RESULT
    elsif @role_limit >= Role::COLLECTION_ADMINISTRATOR &&
      @collection.kind_of?(Collection) &&
      @user.effective_collection_admin?(@collection)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason: "You must be an administrator of the collection." }
  end

  def effective_submitter
    if effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif !@user
      return LOGGED_OUT_RESULT
    elsif @collection.kind_of?(Collection) &&
      @ctx_institution != @collection.institution
      return WRONG_SCOPE_RESULT
    elsif @role_limit >= Role::COLLECTION_SUBMITTER && @user.effective_submitter?(@collection)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason: "You are not authorized to submit to the collection." }
  end

end
