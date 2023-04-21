# frozen_string_literal: true

class ItemsController < ApplicationController

  include MetadataSubmission
  include Search

  before_action :ensure_institution_host, except: :index
  before_action :ensure_logged_in, except: [:file_navigator, :index, :recent,
                                            :show]
  before_action :set_item, except: [:export, :index, :process_review, :recent,
                                    :review]
  before_action :redirect_scope, only: :show
  before_action :authorize_item, except: [:export, :index, :process_review,
                                          :recent, :review]
  before_action :store_location, only: [:index, :recent, :review, :show]

  ##
  # Approves an item.
  #
  # Responds to `PATCH /items/:id/approve`
  #
  def approve
    approve_item(@item)
    RefreshOpensearchJob.perform_later
    toast!(title:   "Item approved",
           message: "This item has been approved.")
    redirect_back fallback_location: item_path(@item)
  end

  ##
  # "Buries" (does **not** delete) an [Item].
  #
  # Burial is an incomplete form of deletion that leaves behind a tombstone
  # record. Buried items can be exhumed via {undelete}.
  #
  # Responds to `POST /items/:id/delete`
  #
  # @see undelete
  #
  def delete
    collection = @item.primary_collection
    begin
      @item.bury!
    rescue => e
      flash['error'] = "#{e}"
    else
      RefreshOpensearchJob.perform_later
      toast!(title:   "Item deleted",
             message: "The item \"#{@item.title}\" has been deleted.")
    ensure
      redirect_to collection || root_url
    end
  end

  ##
  # Renders an HTML table or CSV of download counts by month.
  #
  # Responds to `GET /items/:id/download-counts`
  #
  def download_counts
    results = MonthlyItemDownloadCount.for_item(item:        @item,
                                                start_year:  params[:from_year].to_i,
                                                start_month: params[:from_month].to_i,
                                                end_year:    params[:to_year].to_i,
                                                end_month:   params[:to_month].to_i)
    respond_to do |format|
      format.html do
        @counts_by_month = results
        render partial: "show_download_counts_panel_content"
      end
      format.csv do
        csv = CSV.generate do |csv|
          results.each do |row|
            csv << row.values
          end
        end
        send_data csv,
                  type: "text/csv",
                  disposition: "attachment",
                  filename: "item_#{@item.id}_download_counts.csv"
      end
    end
  end

  ##
  # Used for editing item embargoes.
  #
  # Responds to GET `/items/:id/edit-embargoes` (XHR only)
  #
  def edit_embargoes
    render partial: "items/embargoes_form",
           locals: { item: @item }
  end

  ##
  # Used for editing the owning collections of already-submitted items.
  #
  # Responds to GET `/items/:id/edit-membership` (XHR only)
  #
  def edit_membership
    render partial: "items/membership_form",
           locals: { item: @item }
  end

  ##
  # Used for editing the metadata of already-submitted items.
  #
  # Responds to GET `/items/:id/edit-metadata` (XHR only)
  #
  def edit_metadata
    render partial: "items/metadata_form",
           locals: { item: @item }
  end

  ##
  # Used for editing the basic properties of already-submitted items.
  #
  # Responds to GET `/items/:id/edit-properties` (XHR only)
  #
  def edit_properties
    render partial: "items/properties_form",
           locals: { item: @item }
  end

  ##
  # Used for providing a reason for withdrawing an item.
  #
  # Responds to GET `/items/:id/edit-withdrawal` (XHR only)
  #
  def edit_withdrawal
    render partial: "items/withdrawal_form",
           locals: { item: @item }
  end

  ##
  # Responds to `GET/POST /items/export`. GET returns the form HTML and POST
  # processes the form data. TODO: split off the GET handler into show_export
  #
  def export
    authorize Item
    @registered_elements = RegisteredElement.
      where(institution: current_institution).
      order(:label)
    if request.post?
      # Process elements input into an array of element names.
      elements = params[:elements].reject(&:blank?)
      if elements.empty?
        flash['error'] = "At least one element must be checked."
        render "export", status: :bad_request and return
      end

      # Process handles input.
      handles_str = params[:handles]
      if handles_str.blank?
        flash['error'] = "No handles provided."
        render "export", status: :bad_request and return
      end
      handles         = handles_str.split(",")
      handle_suffixes = handles.map{ |h| h.split("/").last.strip }
      handles         = Handle.where(suffix: handle_suffixes)
      collections     = handles.select{ |h| h.collection_id.present? }.
        map(&:collection).
        select{ |c| c.institution == current_institution }
      units           = handles.select{ |h| h.unit_id.present? }.
        map(&:unit).
        select{ |c| c.institution == current_institution }
      if collections.empty? && units.empty?
        flash['error'] = "The handles provided do not correspond to valid units or collections."
        render "export", status: :bad_request and return
      end
      csv             = CsvExporter.new.export(units:       units,
                                               collections: collections,
                                               elements:    elements)
      send_data csv,
                type:        "text/csv",
                disposition: "attachment",
                filename:    "exported_items.csv"
    end
  end

  ##
  # Responds to `GET /items/:id/file-navigator` (XHR only)
  #
  def file_navigator
    if [Item::Stages::BURIED, Item::Stages::WITHDRAWN].include?(@item.stage)
      render plain: "410 Gone", status: :gone and return
    end
    set_item_bitstreams
    render partial: "items/file_navigator"
  end

  ##
  # Responds to `GET /items`
  #
  def index
    @permitted_params = params.permit(Search::SIMPLE_SEARCH_PARAMS +
                                        Search::advanced_search_params +
                                        Search::RESULTS_PARAMS)
    @start            = @permitted_params[:start].to_i
    @window           = window_size
    @items            = Item.search.
      aggregations(true).
      facet_filters(@permitted_params[:fq]).
      start(@start).
      limit(@window)
    if institution_host?
      @items = @items.institution(current_institution)
    else
      @items = @items.metadata_profile(MetadataProfile.global)
    end
    if @permitted_params[:sort].present?
      @items.order(@permitted_params[:sort] =>
                     (@permitted_params[:direction] == "desc") ? :desc : :asc)
    end
    process_search_input(@items)

    @items        = policy_scope(@items, policy_scope_class: ItemPolicy::Scope)
    @count        = @items.count
    @facets       = @items.facets
    @current_page = @items.page
  end

  ##
  # Processes form input from {review}.
  #
  # Responds to `POST /items/process_review`
  #
  def process_review
    authorize Item
    if params[:items]&.respond_to?(:each)
      case params[:verb]
      when "approve"
        params[:items].each do |item_id|
          item = Item.find(item_id)
          approve_item(item)
        end
        toast!(title:   "Items approved",
               message: "#{params[:items].length} items have been approved.")
      when "reject"
        params[:items].each do |item_id|
          item = Item.find(item_id)
          reject_item(item)
        end
        toast!(title:   "Items rejected",
               message: "#{params[:items].length} items have been rejected.")
      else
        flash['error'] = "Unrecognized verb (this is probably a bug)"
        redirect_back fallback_location: items_review_path and return
      end
      RefreshOpensearchJob.perform_later
    end
    redirect_back fallback_location: items_review_path
  end

  ##
  # Displays a list of recently added items, mainly for the benefit of the
  # Google Scholar crawler.
  #
  # Responds to `GET /recent-items`.
  #
  def recent
    @permitted_params = params.permit(:start)
    @start            = @permitted_params[:start]
    @window           = window_size
    @items            = Item.search.
      institution(current_institution).
      aggregations(false).
      filter_range(Item::IndexFields::CREATED, :gte, 2.weeks.ago).
      order(Item::IndexFields::CREATED => :desc).
      start(@start).
      limit(@window)
    @items            = policy_scope(@items, policy_scope_class: ItemPolicy::Scope)
    @count            = @items.count
    @current_page     = @items.page
  end

  ##
  # Rejects a submitted item.
  #
  # Responds to `PATCH /items/:id/reject`
  #
  def reject
    reject_item(@item)
    RefreshOpensearchJob.perform_later
    toast!(title:   "Item rejected",
           message: "This item has been rejected.")
    redirect_back fallback_location: item_path(@item)
  end

  ##
  # Responds to `GET /items/review`
  #
  def review
    authorize Item
    @permitted_params = params.permit(Search::RESULTS_PARAMS)
    @start            = @permitted_params[:start].to_i
    @window           = window_size
    @items            = Item.search.
        institution(current_institution).
        aggregations(false).
        filter(Item::IndexFields::STAGE, Item::Stages::SUBMITTED).
        order(Item::IndexFields::GROUP_BY_UNIT_AND_COLLECTION_SORT_KEY).
        start(@start).
        limit(@window)
    @count            = @items.count
    @current_page     = @items.page
  end

  ##
  # Responds to `GET /items/:id`
  #
  def show
    @collections = @item.collections
    case @item.stage
    when Item::Stages::SUBMITTING
      redirect_to edit_submission_path(@item), status: :temporary_redirect
    when Item::Stages::BURIED
      render "show_buried", status: :gone and return
    when Item::Stages::WITHDRAWN
      render "show_withdrawn", status: :gone and return
    end
    set_item_bitstreams
  end

  ##
  # Responds to `GET /items/:id/statistics' (XHR only)
  #
  def statistics
    render partial: "statistics_form"
  end

  ##
  # Un-buries/exhumes a buried item, restoring it to the
  # {Item::Stages::APPROVED approved stage}.
  #
  # Responds to `POST /items/:id/undelete`
  #
  # @see delete
  #
  def undelete
    @item.exhume!
  rescue => e
    flash['error'] = "#{e}"
  else
    RefreshOpensearchJob.perform_later
    toast!(title:   "Item undeleted",
           message: "The item \"#{@item.title}\" has been undeleted.")
  ensure
    redirect_to @item
  end

  ##
  # Responds to `PATCH/PUT /items/:id`
  #
  def update
    begin
      UpdateItemCommand.new(item: @item,
                            user: current_user).execute do
        # If we are processing input from the edit-item-membership form
        if params[:collection_item_memberships].respond_to?(:each)
          @item.collection_item_memberships.destroy_all
          params[:collection_item_memberships].each do |membership|
            CollectionItemMembership.create!(collection_id: membership[:collection_id],
                                             item_id:       @item.id,
                                             primary:       (membership[:primary] == "true"))
          end
        else
          if params[:item_bitstream_authorized_groups].respond_to?(:each)
            @item.bitstream_authorizations.destroy_all
            params[:item_bitstream_authorized_groups].select(&:present?).each do |group|
              @item.bitstream_authorizations.build(user_group_id: group)
            end
          end
          @item.update!(item_params)
          build_metadata(@item) # MetadataSubmission concern
          build_embargoes
        end
        @item.save!
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @item.errors.any? ? @item : e },
             status: :bad_request
    else
      RefreshOpensearchJob.perform_later
      toast!(title:   "Item updated",
             message: "The item \"#{@item.title}\" has been updated.")
      render "shared/reload"
    end
  end

  ##
  # Used for uploading bitstreams to already-submitted items.
  #
  # Responds to GET `/items/:id/upload-bitstreams` (XHR only)
  #
  def upload_bitstreams
    render partial: "items/upload_bitstreams_form",
           locals: { item: @item }
  end

  ##
  # Withdraws an approved item.
  #
  # Responds to `PATCH /items/:id/withdraw`
  #
  def withdraw
    UpdateItemCommand.new(item:        @item,
                          user:        current_user,
                          description: "Item was withdrawn.").execute do
      @item.update!(stage: Item::Stages::WITHDRAWN)
    end
    RefreshOpensearchJob.perform_later
    redirect_back fallback_location: item_path(@item)
  end


  private

  def approve_item(item)
    UpdateItemCommand.new(item:        item,
                          user:        current_user,
                          description: "Item was approved.").execute do
      unless item.withdrawn?
        item.assign_handle
        item.move_into_permanent_storage
        item.ingest_into_medusa
      end
      item.approve
      item.save!
      IdealsMailer.item_approved(item).deliver_now
    end
  end

  def authorize_item
    @item ? authorize(@item) : skip_authorization
  end

  def item_params
    params.require(:item).permit(:stage, :stage_reason,
                                 collection_item_memberships_attributes: [
                                   :collection_id, :id, :primary])
  end

  def set_item
    @item           = Item.find(params[:id] || params[:item_id])
    @breadcrumbable = @item
  end

  ##
  # Processes input from the edit-embargoes form.
  #
  def build_embargoes
    if params[:embargoes].respond_to?(:each)
      @item.embargoes.destroy_all
      params[:embargoes].each_value do |embargo|
        next unless embargo[:kind].present?
        @item.embargoes.build(kind:           embargo[:kind].to_i,
                              user_group_ids: embargo[:user_group_ids]&.uniq,
                              reason:         embargo[:reason],
                              perpetual:      embargo[:perpetual] == "true",
                              expires_at:     TimeUtils.ymd_to_time(embargo[:expires_at_year],
                                                                    embargo[:expires_at_month],
                                                                    embargo[:expires_at_day]))
      end
    end
  end

  ##
  # This action works differently depending on whether the current user is a
  # system administrator:
  #
  # * If the current user **is not** a system administrator, and the client is
  #   trying to access an item via a different institution's host, this action
  #   redirects to the same path on the item's host. (Without this action in
  #   place, 403 Forbidden would be returned.) This feature prevents breakage
  #   of external links to items that have been moved to a different
  #   institution (via {Unit#move_to}).
  # * If the current user **is** a system administrator, this action does
  #   nothing. This is because system administrators require the ability to
  #   browse other institutions' items within their own institutional host
  #   scope.
  #
  def redirect_scope
    if @item.institution != current_institution && !current_user&.sysadmin?
      scheme = (Rails.env.development? || Rails.env.test?) ? "http" : "https"
      redirect_to scheme + "://" + @item.institution.fqdn + item_path(@item),
                  allow_other_host: true
    end
  end

  def reject_item(item)
    UpdateItemCommand.new(item:        item,
                          user:        current_user,
                          description: "Item was rejected.").execute do
      item.update!(stage: Item::Stages::REJECTED)
      IdealsMailer.item_rejected(item).deliver_now
    end
  end

  def set_item_bitstreams
    @content_bitstreams  = @item.bitstreams.
      where(bundle: Bitstream::Bundle::CONTENT).
      order("bundle_position", "LOWER(filename)").
      select{ |b| policy(b).show? }
    @other_bitstreams    = @item.bitstreams.
      where("bundle != ?", Bitstream::Bundle::CONTENT).
      order("bundle_position", "LOWER(filename)").
      select{ |b| policy(b).show? }
  end

end