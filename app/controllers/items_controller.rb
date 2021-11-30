# frozen_string_literal: true

class ItemsController < ApplicationController

  before_action :ensure_logged_in, except: [:index, :show]
  before_action :set_item, except: [:index, :process_review, :review]
  before_action :authorize_item, except: [:index, :process_review, :review]

  ##
  # Approves an item.
  #
  # Responds to `PATCH /items/:id/approve`
  #
  def approve
    approve_item(@item)
    ElasticsearchClient.instance.refresh
    redirect_back fallback_location: item_path(@item)
  end

  ##
  # Responds to `DELETE /items/:id`
  #
  # @see cancel_submission
  #
  def destroy
    collection = @item.primary_collection
    begin
      @item.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = @item.title.present? ?
                             "Item \"#{@item.title}\" deleted." : "Item deleted."
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
    from_time = TimeUtils.ymd_to_time(params[:from_year],
                                      params[:from_month],
                                      params[:from_day])
    to_time   = TimeUtils.ymd_to_time(params[:to_year],
                                      params[:to_month],
                                      params[:to_day])
    respond_to do |format|
      format.html do
        @counts_by_month = @item.download_count_by_month(start_time: from_time,
                                                         end_time:   to_time)
        render partial: "show_download_counts_panel_content"
      end
      format.csv do
        csv = CSV.generate do |csv|
          @item.download_count_by_month(start_time: from_time,
                                        end_time:   to_time).each do |row|
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
  # Responds to `GET /items`
  #
  def index
    @start  = results_params[:start].to_i
    @window = window_size
    @items = Item.search.
        institution(current_institution).
        aggregations(true).
        query_all(results_params[:q]).
        facet_filters(results_params[:fq]).
        order(params[:sort]).
        start(@start).
        limit(@window)
    @items            = policy_scope(@items, policy_scope_class: ItemPolicy::Scope)
    @count            = @items.count
    @facets           = @items.facets
    @current_page     = @items.page
    @permitted_params = results_params
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
        flash['success'] = "Approved #{params[:items].length} items."
      when "reject"
        params[:items].each do |item_id|
          item = Item.find(item_id)
          reject_item(item)
        end
        flash['success'] = "Rejected #{params[:items].length} items."
      else
        flash['error'] = "Unrecognized verb (this is probably a bug)"
        redirect_back fallback_location: items_review_path and return
      end
      ElasticsearchClient.instance.refresh
    end
    redirect_back fallback_location: items_review_path
  end

  ##
  # Rejects a submitted item.
  #
  # Responds to `PATCH /items/:id/reject`
  #
  def reject
    reject_item(@item)
    ElasticsearchClient.instance.refresh
    redirect_back fallback_location: item_path(@item)
  end

  ##
  # Responds to `GET /items/review`
  #
  def review
    authorize Item
    @start  = results_params[:start].to_i
    @window = window_size
    @items  = Item.search.
        institution(current_institution).
        aggregations(false).
        filter(Item::IndexFields::STAGE, Item::Stages::SUBMITTED).
        order(Item::IndexFields::GROUP_BY_UNIT_AND_COLLECTION_SORT_KEY).
        start(@start).
        limit(@window)
    @count            = @items.count
    @current_page     = @items.page
    @permitted_params = results_params
  end

  ##
  # Responds to `GET /items/:id`
  #
  def show
    @collections         = @item.collections
    @content_bitstreams  = @item.bitstreams.
      where(bundle: Bitstream::Bundle::CONTENT).
      order("LOWER(original_filename)").
      select{ |b| policy(b).show? }
    @other_bitstreams    = @item.bitstreams.
      where("bundle != ?", Bitstream::Bundle::CONTENT).
      order("LOWER(original_filename)").
      select{ |b| policy(b).show? }

    respond_to do |format|
      format.html
      format.json
      format.zip do
        client       = MedusaDownloaderClient.new(request_context: request_context)
        download_url = client.download_url(item: @item)
        redirect_to download_url, status: :see_other
      end
    end
  end

  ##
  # Responds to `GET /items/:id/statistics' (XHR only)
  #
  def statistics
    render partial: "statistics_form"
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
          build_metadata
          build_embargoes
        end
        @item.save! # trigger a reindex
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @item.errors.any? ? @item : e },
             status: :bad_request
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Item \"#{@item.title}\" updated."
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
    ElasticsearchClient.instance.refresh
    redirect_back fallback_location: item_path(@item)
  end


  private

  def approve_item(item)
    UpdateItemCommand.new(item:        item,
                          user:        current_user,
                          description: "Item was approved, assigned a "\
                          "handle, moved into permanent storage, and "\
                          "ingested into Medusa.").execute do
      item.move_into_permanent_storage
      item.assign_handle
      item.ingest_into_medusa
      item.approve
      item.save!
    end
  end

  def authorize_item
    @item ? authorize(@item) : skip_authorization
  end

  def item_params
    params.require(:item).permit(:discoverable,
                                 collection_item_memberships_attributes: [
                                   :collection_id, :id, :primary])
  end

  def set_item
    @item = Item.find(params[:id] || params[:item_id])
    @breadcrumbable = @item
  end

  ##
  # Processes input from the edit-embargoes form.
  #
  def build_embargoes
    if params[:embargoes].respond_to?(:each)
      @item.embargoes.destroy_all
      params[:embargoes].each_value do |embargo|
        if params[:embargoes].values.length == 1 && !embargo[:download] &&
          !embargo[:full_access]
          return
        end
        @item.embargoes.build(download:    embargo[:download] == "true",
                              full_access: embargo[:full_access] == "true",
                              expires_at:  TimeUtils.ymd_to_time(embargo[:expires_at_year],
                                                                 embargo[:expires_at_month],
                                                                 embargo[:expires_at_day])).save!
      end
    end
  end

  ##
  # Builds and ascribes [AscribedElement]s to the item based on user input.
  # This is done manually because to do it using Rails nested attributes would
  # be harder.
  #
  def build_metadata
    if params[:elements].present?
      ActiveRecord::Base.transaction do
        @item.elements.destroy_all
        params[:elements].select{ |e| e[:string].present? }.each do |element|
          @item.elements.build(registered_element: RegisteredElement.find_by_name(element[:name]),
                               string:             element[:string],
                               uri:                element[:uri])
        end
      end
    end
  end

  def reject_item(item)
    UpdateItemCommand.new(item:        item,
                          user:        current_user,
                          description: "Item was rejected.").execute do
      item.update!(stage: Item::Stages::REJECTED)
    end
  end

end