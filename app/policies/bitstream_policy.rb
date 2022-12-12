# frozen_string_literal: true

class BitstreamPolicy < ApplicationPolicy

  class Scope
    attr_reader :owning_item, :user, :role, :relation

    ##
    # @param request_context [RequestContext]
    # @param relation [ActiveRecord::Relation<Bitstream>]
    # @param owning_item [Item] Item owning the bitstreams in {relation}.
    #
    def initialize(request_context, relation, options = {})
      @owning_item     = options[:owning_item]
      @request_context = request_context
      @user            = request_context&.user
      @role            = request_context&.role_limit || Role::NO_LIMIT
      @relation        = relation
    end

    ##
    # N.B.: this method assumes that the owning item has already been
    # authorized.
    #
    # @return [ActiveRecord::Relation]
    #
    def resolve
      unless BitstreamPolicy.new(@request_context, nil).effective_sysadmin?(user, role)
        # Only collection managers and above can download bitstreams outside
        # of the content bundle.
        unless user&.effective_manager?(owning_item.primary_collection)
          @relation = @relation.where(bundle: Bitstream::Bundle::CONTENT)
        end
        @relation = @relation.where("role <= ?", role) if role
      end
      @relation
    end
  end

  attr_reader :user, :role, :bitstream

  ##
  # @param request_context [RequestContext]
  # @param bitstream [Bitstream]
  #
  def initialize(request_context, bitstream)
    @client_ip       = request_context&.client_ip
    @client_hostname = request_context&.client_hostname
    @user            = request_context&.user
    @role            = request_context&.role_limit
    @bitstream       = bitstream
    @request_context = request_context
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

  def destroy
    ItemPolicy.new(@request_context, bitstream.item).delete_bitstreams
  end

  def download
    show
  end

  def edit
    update
  end

  def index
    # Everyone is authorized, but the policy scope may narrow the results.
    AUTHORIZED_RESULT
  end

  def ingest
    update
  end

  def object
    download
  end

  def show
    if effective_sysadmin?(user, role)
      return AUTHORIZED_RESULT
    elsif !bitstream.item.approved?
      return { authorized: false,
               reason:     "This file's owning item is not approved." }
    elsif bitstream.bundle != Bitstream::Bundle::CONTENT &&
      (!user&.effective_manager?(bitstream.item.primary_collection) || (role && role < Role::COLLECTION_MANAGER))
      return {
        authorized: false,
        reason:     "You must be a manager of the primary collection in "\
                    "which the file's item resides."
      }
    elsif bitstream.item.current_embargoes.any?
      bitstream.item.current_embargoes.each do |embargo|
        unless user && embargo.exempt?(user)
          return { authorized: false,
                   reason:     "This file's owning item is embargoed." }
        end
      end
    elsif role && role < bitstream.role
      return { authorized: false,
               reason:     "Your role is not allowed to access this file." }
    end

    # If there are any user groups authorizing the bitstream by hostname or IP,
    # then only clients with a matching hostname/IP are authorized.
    # Otherwise, anyone is.
    if bitstream.item.bitstream_authorizations.any?
      groups = UserGroup.all_matching_hostname_or_ip(@client_hostname, @client_ip)
      groups.each do |group|
        if bitstream.authorized_by?(group)
          return AUTHORIZED_RESULT
        end
      end
      return { authorized: false,
               reason:     "You are not authorized to access this file." }
    end
    AUTHORIZED_RESULT
  end

  def stream
    download
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

  def viewer
    download
  end

end
