# frozen_string_literal: true

class BitstreamPolicy < ApplicationPolicy

  attr_reader :user, :role, :bitstream

  ##
  # @param request_context [RequestContext]
  # @param bitstream [Bitstream]
  #
  def initialize(request_context, bitstream)
    @user = request_context&.user
    @role = request_context&.role_limit
    @bitstream = bitstream
  end

  def create?
    # user must be logged in
    if user
      # sysadmins can do anything
      return true if role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?

      bitstream.item.all_collections.each do |collection|
        # non-sysadmins can submit to collections for which they have submitter
        # privileges
        return true if role >= Role::COLLECTION_SUBMITTER &&
            user.effective_submitter?(collection)
      end
    end
    false
  end

  def data?
    download?
  end

  def destroy?
    update?
  end

  def download?
    if show?
      if role
        if role >= bitstream.role &&
            (bitstream.bundle == Bitstream::Bundle::CONTENT ||
                user&.effective_manager?(bitstream.item.primary_collection))
          return true
        end
        return false
      end
      return true
    end
    false
  end

  def edit?
    update?
  end

  def ingest?
    update?
  end

  def show?
    (bitstream.item.approved? && bitstream.item.discoverable ||
        (role && role >= Role::SYSTEM_ADMINISTRATOR && user&.sysadmin?)) &&
        (bitstream.exists_in_staging || bitstream.medusa_uuid.present?)
  end

  def update?
    # user must be logged in
    if user
      # sysadmins can do anything
      return true if role >= Role::SYSTEM_ADMINISTRATOR && user.sysadmin?

      bitstream.item.all_collections.each do |collection|
        # unit admins can update bitstreams within their units
        collection.all_units.each do |unit|
          return true if role >= Role::UNIT_ADMINISTRATOR &&
              user.effective_unit_admin?(unit)
        end
        # collection managers can update bitstreams within their collections
        return true if role >= Role::COLLECTION_MANAGER &&
            user.effective_manager?(collection)
      end
    end
    false
  end

end
