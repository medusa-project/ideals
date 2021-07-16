# frozen_string_literal: true

class BitstreamPolicy < ApplicationPolicy

  attr_reader :user, :role, :bitstream

  ##
  # @param request_context [RequestContext]
  # @param bitstream [Bitstream]
  #
  def initialize(request_context, bitstream)
    @user      = request_context&.user
    @role      = request_context&.role_limit
    @bitstream = bitstream
  end

  def create
    if !user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(user, role) # sysadmins can do anything
      return AUTHORIZED_RESULT
    else
      bitstream.item.collections.each do |collection|
        # non-sysadmins can submit to collections for which they have submitter
        # privileges
        return AUTHORIZED_RESULT if role >= Role::COLLECTION_SUBMITTER &&
            user&.effective_submitter?(collection)
      end
    end
    { authorized: false,
      reason:     "You must have submitter privileges to at least one of the "\
                  "collections containing the file." }
  end

  def data
    download
  end

  def destroy
    bitstream.item.stage == Item::Stages::SUBMITTING ?
        update : effective_sysadmin(user, role)
  end

  def download
    can_show = show
    if !can_show[:authorized]
      return can_show
    elsif role && role < bitstream.role
      return { authorized: false,
               reason:     "Your role is not allowed to access this file." }
    elsif bitstream.bundle != Bitstream::Bundle::CONTENT &&
      !user&.effective_manager?(bitstream.item.primary_collection)
      return {
        authorized: false,
        reason:     "You must be a manager of the primary collection in "\
                    "which the file's item resides."
      }
    elsif !bitstream.exists_in_staging && !bitstream.medusa_uuid.present?
      return {
        authorized: false,
        reason: "The file `#{bitstream.original_filename}` associated with "\
          "item ID #{bitstream.item_id} does not exist in storage. "\
          "Please contact us for assistance using the link below."
      }
    elsif bitstream.item.current_embargoes.count > 0
      return { authorized: false,
               reason: "This file's owning item is embargoed." }
    end
    AUTHORIZED_RESULT
  end

  def edit
    update
  end

  def ingest
    update
  end

  def show
    if effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    elsif !bitstream.item.approved?
      return { authorized: false,
               reason:     "This file's owning item is not approved." }
    elsif !bitstream.item.discoverable
      return { authorized: false,
               reason:     "This file's owning item is not discoverable." }
    end
    AUTHORIZED_RESULT
  end

  def update
    if !user
      return LOGGED_OUT_RESULT
    elsif effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    else
      bitstream.item.collections.each do |collection|
        # collection managers can update bitstreams within their collections
        return AUTHORIZED_RESULT if role >= Role::COLLECTION_MANAGER &&
          user.effective_manager?(collection)
        # unit admins can update bitstreams within their units
        collection.units.each do |unit|
          return AUTHORIZED_RESULT if role >= Role::UNIT_ADMINISTRATOR &&
            user.effective_unit_admin?(unit)
        end
      end
    end
    { authorized: false,
      reason:     "You must be either an administrator of a unit, or a "\
                  "manager of a collection, containing the item associated "\
                  "with this file." }
  end

end
