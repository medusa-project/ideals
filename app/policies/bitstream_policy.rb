# frozen_string_literal: true

class BitstreamPolicy < ApplicationPolicy

  class Scope
    attr_reader :owning_item, :user, :role, :relation

    ##
    # @param request_context [RequestContext]
    # @param relation [ActiveRecord::Relation<Bitstream>]
    # @param options [Hash] Hash with an `:owning_item` key representing the
    #        Item owning the bitstreams in {relation}.
    #
    def initialize(request_context, relation, options = {})
      @owning_item     = options[:owning_item]
      @request_context = request_context
      @client_ip       = request_context&.client_ip
      @client_hostname = request_context&.client_hostname
      @user            = request_context&.user
      @role_limit      = request_context&.role_limit || Role::NO_LIMIT
      @relation        = relation
    end

    ##
    # N.B.: this method assumes that the owning item has already been
    # authorized.
    #
    # @return [ActiveRecord::Relation]
    #
    def resolve
      unless BitstreamPolicy.new(@request_context, nil).effective_sysadmin?(@user, @role_limit)
        # Only collection admins and above can download bitstreams outside of
        # the content bundle.
        unless @user&.effective_collection_admin?(@owning_item.primary_collection,
                                                  client_ip:       @client_ip,
                                                  client_hostname: @client_hostname)
          @relation = @relation.where(bundle: Bitstream::Bundle::CONTENT)
        end
        @relation = @relation.where("role <= ?", @role_limit) if @role_limit
      end
      @relation
    end
  end

  WRONG_SCOPE_RESULT = {
    authorized: false,
    reason:     "This file resides in a different institution."
  }

  ##
  # @param request_context [RequestContext]
  # @param bitstream [Bitstream]
  #
  def initialize(request_context, bitstream)
    super(request_context)
    @bitstream = bitstream
  end

  def create
    if effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @bitstream.institution
      return WRONG_SCOPE_RESULT
    elsif !@user
      return LOGGED_OUT_RESULT
    else
      @bitstream.item.collections.each do |collection|
        # non-sysadmins can submit to collections for which they have submitter
        # privileges
        return AUTHORIZED_RESULT if @role_limit >= Role::COLLECTION_SUBMITTER &&
          @user&.effective_collection_submitter?(collection,
                                                 client_ip:       @client_ip,
                                                 client_hostname: @client_hostname)
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
    ItemPolicy.new(@request_context, @bitstream.item).delete_bitstreams
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
    if effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @bitstream.institution
      return WRONG_SCOPE_RESULT
    elsif @bitstream.item.stage > Item::Stages::APPROVED
      return { authorized: false,
               reason:     "This file's owning item is not authorized." }
    elsif @bitstream.bundle != Bitstream::Bundle::CONTENT &&
      (!@user&.effective_collection_admin?(@bitstream.item.effective_primary_collection,
                                           client_ip:       @client_ip,
                                           client_hostname: @client_hostname) ||
        (@role_limit && @role_limit < Role::COLLECTION_ADMINISTRATOR))
      return {
        authorized: false,
        reason:     "You must be an administrator of the primary collection "\
                    "in which the file's item resides."
      }
    elsif @bitstream.item.current_embargoes.any?
      @bitstream.item.current_embargoes.each do |embargo|
        unless @user && embargo.exempt?(user:            @user,
                                        client_ip:       @client_ip,
                                        client_hostname: @client_hostname)
          return { authorized: false,
                   reason:     "This file's owning item is embargoed." }
        end
      end
    elsif (@role_limit && @role_limit < @bitstream.role) ||
      (!@user && @bitstream.role > Role::LOGGED_OUT) ||
      (@user && @bitstream.role >= Role::SYSTEM_ADMINISTRATOR) ||
      (@user && @bitstream.role >= Role::COLLECTION_SUBMITTER && !@user.effective_collection_submitter?(@bitstream.item.effective_primary_collection,
                                                                                                        client_ip:       @client_ip,
                                                                                                        client_hostname: @client_hostname)) ||
      (@user && @bitstream.role >= Role::COLLECTION_ADMINISTRATOR && !@user.effective_collection_admin?(@bitstream.item.effective_primary_collection,
                                                                                                        client_ip:       @client_ip,
                                                                                                        client_hostname: @client_hostname)) ||
      (@user && @bitstream.role >= Role::UNIT_ADMINISTRATOR && !@user.effective_unit_admin?(@bitstream.item.effective_primary_unit,
                                                                                            client_ip:       @client_ip,
                                                                                            client_hostname: @client_hostname)) ||
      (@user && @bitstream.role >= Role::INSTITUTION_ADMINISTRATOR && !@user.effective_institution_admin?(@bitstream.institution,
                                                                                                          client_ip:       @client_ip,
                                                                                                          client_hostname: @client_hostname))
      return { authorized: false,
               reason:     "Your role is not allowed to access this file." }
    end

    # If there are any user groups authorizing the bitstream by hostname or IP,
    # then only clients with a matching hostname/IP are authorized.
    # Otherwise, anyone is.
    if @bitstream.item.bitstream_authorizations.any?
      groups = UserGroup.all_matching_hostname_or_ip(@client_hostname, @client_ip)
      groups.each do |group|
        if @bitstream.authorized_by?(group)
          return AUTHORIZED_RESULT
        end
      end
      return { authorized: false,
               reason:     "You are not authorized to access this file." }
    end
    AUTHORIZED_RESULT
  end

  ##
  # Used only in views to determine whether to show bitstream details.
  #
  def show_details
    effective_sysadmin(@user, @role_limit)
  end

  ##
  # Subset of {show_details} to determine whether to show the bitstream minimum
  # access role specifically.
  #
  def show_role
    if @ctx_institution != @bitstream.institution
      return WRONG_SCOPE_RESULT
    elsif !@user
      return LOGGED_OUT_RESULT
    end
    @bitstream.item.collections.each do |collection|
      if @role_limit >= Role::COLLECTION_ADMINISTRATOR &&
        @user.effective_collection_admin?(collection,
                                          client_hostname: @client_hostname,
                                          client_ip:       @client_ip)
        return AUTHORIZED_RESULT
      end
    end
    { authorized: false,
      reason:     "You are not authorized to access this file." }
  end

  def update
    if effective_sysadmin?(@user, @role_limit)
      return AUTHORIZED_RESULT
    elsif @ctx_institution != @bitstream.institution
      return WRONG_SCOPE_RESULT
    elsif !@user
      return LOGGED_OUT_RESULT
    else
      @bitstream.item.collections.each do |collection|
        # collection admins can update bitstreams within their collections
        return AUTHORIZED_RESULT if @role_limit >= Role::COLLECTION_ADMINISTRATOR &&
          @user.effective_collection_admin?(collection,
                                            client_ip:       @client_ip,
                                            client_hostname: @client_hostname)
        # unit admins can update bitstreams within their units
        collection.units.each do |unit|
          return AUTHORIZED_RESULT if @role_limit >= Role::UNIT_ADMINISTRATOR &&
            @user.effective_unit_admin?(unit,
                                        client_ip:       @client_ip,
                                        client_hostname: @client_hostname)
        end
      end
    end
    { authorized: false,
      reason:     "You must be an administrator of a unit or collection "\
                  "containing the item associated with this file." }
  end

  def viewer
    download
  end

end
