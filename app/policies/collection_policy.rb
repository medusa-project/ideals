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
    super(request_context)
    @collection = collection
  end

  def all_files
    export_items
  end

  def bury
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @collection.institution
      return WRONG_SCOPE_RESULT
    elsif effective_institution_admin?(@user, @collection.institution, @role_limit)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason:     "You must be an administrator of the institution in which "\
                  "the collection resides." }
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
      @user.effective_collection_admin?(Collection.find(new_parent_id),
                                        client_ip:       @client_ip,
                                        client_hostname: @client_hostname)
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

  def destroy
    effective_sysadmin(@user, @role_limit)
  end

  def edit_administering_groups
    update
  end

  def edit_administering_users
    update
  end

  def edit_collection_membership
    update
  end

  def edit_properties
    update
  end

  def edit_submitting_groups
    update
  end

  def edit_submitting_users
    update
  end

  def edit_unit_membership
    update
  end

  def exhume
    bury
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
    unless @collection.accepts_submissions
      return { authorized: false,
               reason: "This collection is not accepting submissions." }
    end
    effective_submitter
  end

  def update
    create
  end


  private

  def effective_admin
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit) ||
      effective_institution_admin?(@user, @ctx_institution, @role_limit)
      return AUTHORIZED_RESULT
    elsif @collection.kind_of?(Collection) &&
      @ctx_institution != @collection.institution
      return WRONG_SCOPE_RESULT
    elsif @role_limit >= Role::COLLECTION_ADMINISTRATOR &&
      @collection.kind_of?(Collection) &&
      @user.effective_collection_admin?(@collection,
                                        client_ip:       @client_ip,
                                        client_hostname: @client_hostname)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason: "You must be an administrator of the collection." }
  end

  def effective_submitter
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @collection.kind_of?(Collection) &&
      @ctx_institution != @collection.institution
      return WRONG_SCOPE_RESULT
    elsif @role_limit >= Role::COLLECTION_SUBMITTER &&
      @user.effective_collection_submitter?(@collection,
                                            client_ip:       @client_ip,
                                            client_hostname: @client_hostname)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason: "You are not authorized to submit to the collection." }
  end

end
