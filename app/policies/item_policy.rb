# frozen_string_literal: true

class ItemPolicy < ApplicationPolicy

  class Scope

    ##
    # @param request_context [RequestContext]
    # @param relation [ItemRelation]
    #
    def initialize(request_context, relation, options = {})
      @request_context = request_context
      @user            = request_context&.user
      @role_limit      = request_context&.role_limit || Role::NO_LIMIT
      @relation        = relation
    end

    ##
    # @return [ItemRelation]
    #
    def resolve
      @relation.
        must_not(Item::IndexFields::STAGE, [Item::Stages::NEW,
                                            Item::Stages::SUBMITTING,
                                            Item::Stages::SUBMITTED,
                                            Item::Stages::REJECTED,
                                            Item::Stages::WITHDRAWN,
                                            Item::Stages::BURIED]).
        non_embargoed
    end
  end

  NOT_INSTITUTION_ADMIN_RESULT = {
    authorized: false,
    reason:     "You must be an administrator of the institution in which "\
                "this item resides."
  }
  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This item resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param item [Item]
  #
  def initialize(request_context, item)
    @user            = request_context&.user
    @ctx_institution = request_context&.institution
    @role_limit      = request_context&.role_limit
    @item            = item
  end

  def approve
    review
  end

  def bury
    exhume
  end

  def create
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @item.institution
      return WRONG_SCOPE_RESULT
    else
      @item.collections.each do |collection|
        # non-sysadmins can submit to collections for which they have submitter
        # privileges
        return AUTHORIZED_RESULT if (@role_limit >= Role::COLLECTION_SUBMITTER) &&
          @user&.effective_collection_submitter?(collection)
      end
    end
    { authorized: false,
      reason: "You do not have permission to submit to this collection." }
  end

  def delete_bitstreams
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @item.institution
      return WRONG_SCOPE_RESULT
    elsif @item.stage == Item::Stages::SUBMITTING
      return update
    elsif effective_institution_admin?(@user, @ctx_institution, @role_limit)
      return AUTHORIZED_RESULT
    end
    NOT_INSTITUTION_ADMIN_RESULT
  end

  def destroy
    effective_sysadmin(@user, @role_limit)
  end

  def download_counts
    return { authorized: false,
             reason:     "This item has been deleted." } if @item.buried?
    statistics
  end

  def edit_embargoes
    update
  end

  def edit_membership
    update
  end

  def edit_metadata
    update
  end

  def edit_properties
    update
  end

  def edit_withdrawal
    withdraw
  end

  def exhume
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @item.institution
      return WRONG_SCOPE_RESULT
    elsif (@role_limit >= Role::INSTITUTION_ADMINISTRATOR) &&
      @user.effective_institution_admin?(@item.institution)
      return AUTHORIZED_RESULT
    end
    NOT_INSTITUTION_ADMIN_RESULT
  end

  def export
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif (@role_limit >= Role::INSTITUTION_ADMINISTRATOR) &&
      effective_institution_admin?(@user, @user.institution, @role_limit)
      return AUTHORIZED_RESULT
    end
    NOT_INSTITUTION_ADMIN_RESULT
  end

  ##
  # N.B. This method includes all of the rules of {show} but is more
  # restrictive as it takes into account download-only embargoes.
  #
  def file_navigator
    result = show
    return result if !result[:authorized]

    if effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @item.institution
      return WRONG_SCOPE_RESULT
    end
    @item.current_embargoes.each do |embargo|
      if !@user || !embargo.exempt?(@user) || (@role_limit && @role_limit <= Role::LOGGED_OUT)
        if embargo.user_groups.length > 1
          reason = embargo.public_reason
          if reason.blank?
            reason = "This item's files can only be accessed by the "\
                     "following groups: " + embargo.user_groups.map(&:name).join(", ")
          end
        elsif embargo.user_groups.length == 1
          if embargo.user_groups.first.key == "uiuc"
            # This is a special UIUC exception from IR-242
            reason = "This item is only available for download by members of "\
                     "the University of Illinois community. Students, "\
                     "faculty, and staff at the U of I may log in with your "\
                     "NetID and password to view the item. If you are trying "\
                     "to access an Illinois-restricted dissertation or "\
                     "thesis, you can request a copy through your library's "\
                     "Inter-Library Loan office or purchase a copy directly "\
                     "from ProQuest."
          else
            reason = embargo.public_reason
            if reason.blank?
              reason = "This item's files can only be accessed by the "\
                       "#{embargo.user_groups.first.name} group."
            end
          end
        else
          # Verbiage also from IR-242
          reason = "This item is closed and only viewable by specific users."
        end
        return { authorized: false, reason: reason }
      end
    end
    AUTHORIZED_RESULT
  end

  def index
    AUTHORIZED_RESULT
  end

  def ingest
    upload_bitstreams
  end

  def process_review
    review
  end

  def reject
    review
  end

  def review
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @item.kind_of?(Item) && @ctx_institution != @item.institution
      return WRONG_SCOPE_RESULT
    end
    effective_institution_admin(@user, @ctx_institution, @role_limit)
  end

  def show
    if effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @item.institution
      return WRONG_SCOPE_RESULT
    # Withdrawn & buried items are authorized but are shown in a special,
    # limited view.
    elsif effective_institution_admin?(@user, @ctx_institution, @role_limit) ||
      @item.withdrawn? || @item.buried?
      return AUTHORIZED_RESULT
    elsif !@item.approved?
      return { authorized: false, reason: "This item is not approved." }
    elsif @item.embargoed_for?(@user)
      return { authorized: false, reason: "This item is embargoed." }
    end
    AUTHORIZED_RESULT
  end

  ##
  # N.B.: this is not a controller method.
  #
  def show_access
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @item.institution
      return WRONG_SCOPE_RESULT
    elsif @user
      @item.collections.each do |collection|
        # collection admins can see access of items within their collections
        return AUTHORIZED_RESULT if (@role_limit >= Role::COLLECTION_ADMINISTRATOR) &&
          @user.effective_collection_admin?(collection)
        # unit admins can see access of items within their units
        collection.units.each do |unit|
          return AUTHORIZED_RESULT if (@role_limit >= Role::UNIT_ADMINISTRATOR) &&
            @user.effective_unit_admin?(unit)
        end
      end
    end
    { authorized: false,
      reason:     "You must be an administrator of one of the collections or "\
                  "units in which this item resides." }
  end

  ##
  # Authorization to show **all** metadata including non-public metadata.
  #
  # @see show_metadata
  #
  def show_all_metadata
    show_access
  end

  def show_collections
    show_metadata
  end

  def show_embargoes
    show_access
  end

  def show_events
    show_access
  end

  ##
  # Authorization to show public metadata only.
  #
  # @see show_all_metadata
  #
  def show_metadata
    if effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @item.institution
      return WRONG_SCOPE_RESULT
    end
    result = show_access
    return result if result[:authorized]
    # At this point we know that the user's role is beneath that of collection
    # administrator, so they are authorized except to withdrawn/buried items.
    case @item.stage
    when Item::Stages::WITHDRAWN
      { authorized: false, reason: "This item has been withdrawn." }
    when Item::Stages::BURIED
      { authorized: false, reason: "This item has been deleted." }
    else
      AUTHORIZED_RESULT
    end
  end

  def show_properties
    show_access
  end

  def statistics
    return { authorized: false,
             reason:     "This item has been deleted." } if @item.buried?
    show
  end

  def update
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @item.institution
      return WRONG_SCOPE_RESULT
    elsif (@role_limit >= Role::COLLECTION_SUBMITTER) &&
      @user == @item.submitter && @item.submitting?
      return AUTHORIZED_RESULT
    elsif @user
      @item.collections.each do |collection|
        # collection admins can update items within their collections
        return AUTHORIZED_RESULT if (@role_limit >= Role::COLLECTION_ADMINISTRATOR) &&
          @user.effective_collection_admin?(collection)
        # unit admins can update items within their units
        collection.units.each do |unit|
          return AUTHORIZED_RESULT if (@role_limit >= Role::UNIT_ADMINISTRATOR) &&
            @user.effective_unit_admin?(unit)
        end
      end
    end
    { authorized: false,
      reason:     "You must be either the submitter of the item or an "\
                  "administrator of one of the collections or units in "\
                  "which it resides." }
  end

  def upload_bitstreams
    update
  end

  def withdraw
    if !@user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @item.institution
      return WRONG_SCOPE_RESULT
    elsif (@role_limit >= Role::UNIT_ADMINISTRATOR) &&
      @user&.effective_unit_admin?(@item.effective_primary_unit)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason:     "You must be an administrator of the item's primary unit." }
  end

end
