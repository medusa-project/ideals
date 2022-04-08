# frozen_string_literal: true

class ItemPolicy < ApplicationPolicy

  class Scope
    attr_reader :user, :role, :relation

    ##
    # @param request_context [RequestContext]
    # @param relation [ItemRelation]
    #
    def initialize(request_context, relation, options = {})
      @request_context = request_context
      @user            = request_context&.user
      @role            = request_context&.role_limit || Role::NO_LIMIT
      @relation        = relation
    end

    ##
    # @return [ItemRelation]
    #
    def resolve
      if ItemPolicy.new(@request_context, nil).effective_sysadmin?(user, role)
        relation
      else
        relation.
          filter(Item::IndexFields::DISCOVERABLE, true).
          filter(Item::IndexFields::STAGE, Item::Stages::APPROVED).
          must_not_range("#{Item::IndexFields::EMBARGOES}.#{Embargo::IndexFields::EXPIRES_AT}",
                         :gt,
                         Time.now.strftime("%Y-%m-%d"))
      end
    end
  end

  attr_reader :user, :role, :item

  ##
  # @param request_context [RequestContext]
  # @param item [Item]
  #
  def initialize(request_context, item)
    @user = request_context&.user
    @role = request_context&.role_limit
    @item = item
  end

  def approve
    review
  end

  def cancel_submission
    update
  end

  def create
    if effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    else
      item.collections.each do |collection|
        # non-sysadmins can submit to collections for which they have submitter
        # privileges
        return AUTHORIZED_RESULT if (!role || role >= Role::COLLECTION_SUBMITTER) &&
          user&.effective_submitter?(collection)
      end
    end
    { authorized: false,
      reason: "You do not have permission to submit to this collection." }
  end

  def delete
    if !user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    elsif (!role || role >= Role::INSTITUTION_ADMINISTRATOR) &&
      user.effective_institution_admin?(item.institution)
      return AUTHORIZED_RESULT
    elsif (!role || role >= Role::COLLECTION_SUBMITTER) &&
      user == item.submitter && item.submitting?
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason:     "You must be an administrator of the institution in which "\
                  "this item resides." }
  end

  def download_counts
    return { authorized: false,
             reason:     "This item has been deleted." } if item.buried?
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

  def export
    if !user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    elsif (!role || role >= Role::INSTITUTION_ADMINISTRATOR) &&
      user.any_institution_admin?
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason:     "You must be a system or institution administrator." }
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
    effective_sysadmin(user, role)
  end

  def show
    # Withdrawn & buried items are authorized but are shown in a special,
    # limited view.
    if effective_sysadmin?(user, role) || @item.withdrawn? || @item.buried?
      return AUTHORIZED_RESULT
    elsif !@item.approved?
      return { authorized: false, reason: "This item is not approved." }
    elsif !@item.discoverable
      return { authorized: false, reason: "This item is not discoverable." }
    elsif @item.current_embargoes.where(full_access: true).count > 0
      @item.current_embargoes.where(full_access: true).each do |embargo|
        unless user && embargo.exempt?(user)
          return { authorized: false, reason: "This item is embargoed." }
        end
      end
    end
    AUTHORIZED_RESULT
  end

  ##
  # N.B.: this is not a controller method.
  #
  def show_access
    if effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    elsif user
      item.collections.each do |collection|
        # collection managers can see access of items within their collections
        return AUTHORIZED_RESULT if (!role || role >= Role::COLLECTION_MANAGER) &&
          user.effective_manager?(collection)
        # unit admins can see access of items within their units
        collection.units.each do |unit|
          return AUTHORIZED_RESULT if (!role || role >= Role::UNIT_ADMINISTRATOR) &&
            user.effective_unit_admin?(unit)
        end
      end
    end
    { authorized: false,
      reason:     "You must be either a manager of one of the collections, or "\
                  "an administrator of one of the units, in which this item "\
                  "resides." }
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
    result = show_access
    return result if result[:authorized]
    # At this point we know that the user's role is beneath that of collection
    # manager, so they are authorized except to withdrawn/buried items.
    case item.stage
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

  def show_sysadmin_content
    effective_sysadmin(user, role)
  end

  def statistics
    return { authorized: false,
             reason:     "This item has been deleted." } if item.buried?
    show
  end

  def undelete
    if !user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    elsif (!role || role >= Role::INSTITUTION_ADMINISTRATOR) &&
      user.effective_institution_admin?(item.institution)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason:     "You must be an administrator of the institution in which "\
                  "this item resides." }
  end

  def update
    if effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    elsif (!role || role >= Role::COLLECTION_SUBMITTER) &&
        user == item.submitter && item.submitting?
      return AUTHORIZED_RESULT
    elsif user
      item.collections.each do |collection|
        # collection managers can update items within their collections
        return AUTHORIZED_RESULT if (!role || role >= Role::COLLECTION_MANAGER) &&
          user.effective_manager?(collection)
        # unit admins can update items within their units
        collection.units.each do |unit|
          return AUTHORIZED_RESULT if (!role || role >= Role::UNIT_ADMINISTRATOR) &&
            user.effective_unit_admin?(unit)
        end
      end
    end
    { authorized: false,
      reason:     "You must be either the submitter of the item, a manager "\
                  "of one of the collections in which it resides, or an "\
                  "administrator of one of the units in which this it "\
                  "resides." }
  end

  def upload_bitstreams
    update
  end

  def withdraw
    if (!role || role >= Role::UNIT_ADMINISTRATOR) &&
      user&.effective_unit_admin?(item.effective_primary_unit)
      return AUTHORIZED_RESULT
    end
    { authorized: false,
      reason:     "You must be an administrator of the item's primary unit." }
  end

end
