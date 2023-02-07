# frozen_string_literal: true

class CollectionsController < ApplicationController

  include Search

  before_action :ensure_logged_in, only: [:all_files, :create, :delete,
                                          :edit_collection_membership,
                                          :edit_managers, :edit_properties,
                                          :edit_submitters,
                                          :edit_unit_membership,
                                          :edit_user_access, :show_access,
                                          :show_review_submissions, :undelete,
                                          :update]
  before_action :set_collection, except: [:create, :index]
  before_action :check_buried, except: [:create, :index, :show, :undelete]
  before_action :authorize_collection, except: [:create, :index]
  before_action :store_location, only: [:index, :show]

  ##
  # Responds to `GET /collections/:collection_id/all-files`
  #
  def all_files
    respond_to do |format|
      format.zip do
        item_ids = policy_scope(Item.search.filter(Item::IndexFields::COLLECTIONS, @collection.id),
                                policy_scope_class: ItemPolicy::Scope).to_id_a
        if item_ids.any?
          download = Download.create!(institution: @collection.institution,
                                      ip_address:  request.remote_ip)
          ZipItemsJob.perform_later(item_ids, download)
          redirect_to download_url(download)
        else
          head :no_content
        end
      end
    end
  end

  ##
  # Renders a partial for the expandable unit list used in {index}. Has the
  # same permissions as {show}.
  #
  # Responds to `GET /collections/:collection_id/children` (XHR only)
  #
  def children
    @collections = Collection.search.
        institution(current_institution).
        filter(Collection::IndexFields::PARENT, @collection.id).
        filter(Collection::IndexFields::UNIT_DEFAULT, false).
        order("#{Collection::IndexFields::TITLE}.sort").
        limit(999)
    render partial: "children"
  end

  ##
  # Responds to `POST /collections`.
  #
  def create
    begin
      ActiveRecord::Base.transaction do
        @collection              = Collection.new(collection_params)
        @collection.institution  = current_institution
        @collection.primary_unit = Unit.find_by_id(params[:primary_unit_id])
        # We need to save now in order to assign the collection an ID which
        # many of the authorization methods will need. If authorization fails,
        # the transaction will roll back.
        @collection.save!
        authorize @collection
        @collection.save!
      end
    rescue NotAuthorizedError => e
      raise e
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @collection.errors.any? ? @collection : e },
             status: :bad_request
    else
      RefreshOpensearchJob.perform_later
      toast!(title:   "Collection created",
             message: "The \"#{@collection.title}\" collection has been created.")
      render 'shared/reload'
    end
  end

  ##
  # Buries--does **not** delete--a collection.
  #
  # Responds to `POST /collections/:id/delete`
  #
  # @see undelete
  #
  def delete
    primary_unit = @collection.primary_unit
    parent       = @collection.parent
    title        = @collection.title
    begin
      ActiveRecord::Base.transaction do
        @collection.bury!
      end
    rescue => e
      flash['error'] = "#{e}"
      redirect_to @collection
    else
      RefreshOpensearchJob.perform_later
      toast!(title:   "Collection deleted",
             message: "The \"#{title}\" collection has been deleted.")
      redirect_to(parent || primary_unit)
    end
  end

  ##
  # Responds to `GET /collections/:collection_id/edit-collection-membership`
  # (XHR only)
  #
  def edit_collection_membership
    render partial: 'collections/collection_membership_form',
           locals: { collection: @collection }
  end

  ##
  # Responds to `GET /collections/:collection_id/edit-managers`
  # (XHR only)
  #
  def edit_managers
    render partial: 'collections/managers_form',
           locals: { collection: @collection }
  end

  ##
  # Responds to GET `/collections/:collection_id/edit-properties` (XHR only)
  #
  def edit_properties
    render partial: 'collections/properties_form',
           locals: { collection: @collection }
  end

  ##
  # Responds to `GET /collections/:collection_id/edit-submitters`
  # (XHR only)
  #
  def edit_submitters
    render partial: 'collections/submitters_form',
           locals: { collection: @collection }
  end

  ##
  # Responds to `GET /collections/:id/edit-unit-membership` (XHR only)
  #
  def edit_unit_membership
    render partial: 'collections/unit_membership_form',
           locals: { collection: @collection,
                     primary_unit: @collection.primary_unit }
  end

  ##
  # Responds to `GET /collections/:id/edit-user-access` (XHR only)
  #
  def edit_user_access
    render partial: 'collections/user_access_form',
           locals: { collection: @collection }
  end

  ##
  # Responds to `GET /collections` (JSON only)
  #
  def index
    if params[:format] != "json"
      render plain: "Not Acceptable",
             status: :not_acceptable and return
    end
    @permitted_params = params.permit(Search::RESULTS_PARAMS +
                                        Search::SIMPLE_SEARCH_PARAMS)
    @start            = @permitted_params[:start].to_i
    @window           = window_size
    @collections      = Collection.search.
        institution(current_institution).
        aggregations(false).
        query_searchable_fields(@permitted_params[:q]).
        order("#{Collection::IndexFields::TITLE}.sort").
        start(@start).
        limit(@window)
    @count            = @collections.count
    @current_page     = @collections.page
  end

  ##
  # Renders item download counts by month as HTML and CSV.
  #
  # Responds to `GET /collections/:id/item-download-counts`
  #
  def item_download_counts
    @items = MonthlyItemDownloadCount.collection_download_counts_by_item(
      collection:  @collection,
      start_year:  params[:from_year].to_i,
      start_month: params[:from_month].to_i,
      end_year:    params[:to_year].to_i,
      end_month:   params[:to_month].to_i)

    # The items array contains item IDs and download counts but not titles.
    # So here we will insert them.
    AscribedElement.
      where(registered_element: current_institution.title_element).
      where(item_id: @items.map{ |row| row['id'] }).pluck(:item_id, :string).each do |asc_e|
      row = @items.find{ |r| r['id'] == asc_e[0] }
      row['title'] = asc_e[1] if row
    end

    respond_to do |format|
      format.html do
        render partial: "show_downloads_by_item"
      end
      format.csv do
        csv = CSV.generate do |csv|
          csv << ["Month", "Downloads"]
          @items.each do |row|
            csv << row.values
          end
        end
        send_data csv,
                  type: "text/csv",
                  disposition: "attachment",
                  filename: "collection_#{@collection.id}_download_counts.csv"
      end
    end
  end

  ##
  # Renders results within the items tab in show-collection view.
  #
  # Responds to `GET /collections/:id/item-results`
  #
  def item_results
    set_item_results_ivars
    render partial: "items/listing"
  end

  ##
  # Responds to `GET /collections/:id`
  #
  def show
    if @collection.buried
      render "show_buried", status: :gone and return
    end
    review_items  = review_items(0, 0)
    @review_count = review_items.count
  end

  ##
  # Renders HTML for the properties tab in show-collection view.
  #
  # Responds to `GET /collections/:id/about`
  #
  def show_about
    @metadata_profile    = @collection.effective_metadata_profile
    @submission_profile  = @collection.effective_submission_profile
    @num_downloads       = MonthlyCollectionItemDownloadCount.sum_for_collection(collection: @collection)
    @num_submitted_items = @collection.submitted_item_count
    @subcollections      = Collection.search.
      institution(current_institution).
      parent_collection(@collection).
      include_children(true).
      order("#{Collection::IndexFields::TITLE}.sort").
      limit(999)
    render partial: "show_about_tab"
  end

  ##
  # Renders HTML for the access tab in show-collection view.
  #
  # Responds to `GET /collections/:id/access` (XHR only)
  #
  def show_access
    render partial: "show_access_tab"
  end

  ##
  # Renders HTML for the items tab in show-collection view.
  #
  # Responds to `GET /collections/:id/items`
  #
  def show_items
    set_item_results_ivars
    respond_to do |format|
      format.html do
        render partial: "show_items_tab"
      end
      format.csv do
        authorize(@collection, policy_method: :export_items)
        send_data(CsvExporter.new.export_collection(@collection),
                  type:        "text/csv",
                  disposition: "attachment",
                  filename:    "collection_#{@collection.id}_items.csv")
      end
    end
  end

  ##
  # Renders HTML for the review submissions tab in show-collection view.
  #
  # Responds to `GET /collections/:id/review-submissions`
  #
  def show_review_submissions
    @review_permitted_params = params.permit(Search::RESULTS_PARAMS)
    @review_start            = @review_permitted_params[:start].to_i
    @review_window           = window_size
    @review_items            = review_items(@review_start, @review_window)
    @review_count            = @review_items.count
    @review_current_page     = @review_items.page
    render partial: "show_review_submissions_tab"
  end

  ##
  # Renders HTML for the statistics tab in show-collection view.
  #
  # Responds to `GET /collections/:id/statistics` (XHR only)
  #
  def show_statistics
    render partial: "show_statistics_tab"
  end

  ##
  # Renders statistics within a date range as HTML and CSV.
  #
  # Responds to `GET /collections/:id/statistics-by-range`
  #
  def statistics_by_range
    begin
      from_time = TimeUtils.ymd_to_time(params[:from_year],
                                        params[:from_month],
                                        params[:from_day])
      to_time   = TimeUtils.ymd_to_time(params[:to_year],
                                        params[:to_month],
                                        params[:to_day])
      # These two queries could probably be consolidated, but this will do for
      # now.
      @counts_by_month = @collection.submitted_item_count_by_month(start_time: from_time,
                                                                   end_time:   to_time)
      downloads_by_month = MonthlyCollectionItemDownloadCount.for_collection(
        collection:  @collection,
        start_year:  params[:from_year].to_i,
        start_month: params[:from_month].to_i,
        end_year:    params[:to_year].to_i,
        end_month:   params[:to_month].to_i)
      @counts_by_month.each_with_index do |m, i|
        m['item_count'] = m['count']
        m['dl_count']   = downloads_by_month[i]['dl_count']
        m.delete('count')
      end
    rescue ArgumentError => e
      render plain: "#{e}", status: :bad_request
      return
    end

    respond_to do |format|
      format.html do
        render partial: "show_statistics_by_month"
      end
      format.csv do
        csv = CSV.generate do |csv|
          csv << ["Month", "Submitted Items", "Downloads"]
          @counts_by_month.each do |row|
            csv << row.values
          end
        end
        send_data csv,
                  type: "text/csv",
                  disposition: "attachment",
                  filename: "collection_#{@collection.id}_statistics.csv"
      end
    end
  end

  ##
  # Exhumes a buried collection.
  #
  # Responds to `POST /collections/:id/undelete`
  #
  # @see delete
  #
  def undelete
    ActiveRecord::Base.transaction do
      @collection.exhume!
    end
  rescue => e
    flash['error'] = "#{e}"
  else
    RefreshOpensearchJob.perform_later
    toast!(title:   "Collection undeleted",
           message: "The \"#{@collection.title}\" collection has been undeleted.")
  ensure
    redirect_to @collection
  end

  ##
  # Responds to `PATCH/PUT /collections/:id`
  #
  def update
    if params[:collection] && params[:collection][:parent_id] &&
        !policy(@collection).change_parent?(params[:collection][:parent_id])
      raise NotAuthorizedError,"Cannot move a collection into a "\
            "collection of which you are not an effective manager."
    end
    begin
      ActiveRecord::Base.transaction do
        assign_users
        assign_user_groups
        assign_primary_unit
        @collection.update!(collection_params)
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @collection.errors.any? ? @collection : e },
             status: :bad_request
    else
      RefreshOpensearchJob.perform_later
      toast!(title:   "Collection updated",
             message: "Collection \"#{@collection.title}\" has been updated.")
      render 'shared/reload'
    end
  end


  private

  def assign_primary_unit
    if params[:primary_unit_id]
      unit = Unit.find(params[:primary_unit_id])
      @collection.unit_collection_memberships.destroy_all
      @collection.unit_collection_memberships.build(unit_id: unit.id,
                                                    primary: true)
      @collection.update!(institution_id: unit.institution_id)
    end
  end

  def assign_user_groups
    # Managers
    if params[:managing_user_group_ids]
      @collection.manager_groups.destroy_all
      params[:managing_user_group_ids].select(&:present?).each do |user_group_id|
        @collection.manager_groups.build(user_group_id: user_group_id).save!
      end
    end
    # Submitters
    if params[:submitting_user_group_ids]
      @collection.submitter_groups.destroy_all
      params[:submitting_user_group_ids].select(&:present?).each do |user_group_id|
        @collection.submitter_groups.build(user_group_id: user_group_id).save!
      end
    end
  end

  def assign_users
    # Managers
    if params[:managers]
      @collection.managers.destroy_all
      if params[:managers].respond_to?(:each)
        params[:managers].select(&:present?).each do |user_str|
          user = User.from_autocomplete_string(user_str)
          @collection.errors.add(:managers,
                               "includes a user that does not exist") unless user
          @collection.managing_users << user
        end
      end
    end
    # Submitters
    if params[:submitters]
      @collection.submitters.destroy_all
      if params[:submitters].respond_to?(:each)
        params[:submitters].select(&:present?).each do |user_str|
          user = User.from_autocomplete_string(user_str)
          @collection.errors.add(:submitters,
                               "includes a user that does not exist") unless user
          @collection.submitting_users << user
        end
      end
    end
  end

  def authorize_collection
    @collection ? authorize(@collection) : skip_authorization
  end

  def check_buried
    raise GoneError if @collection&.buried
  end

  def review_items(start, limit)
    Item.search.
      institution(current_institution).
      aggregations(false).
      filter(Item::IndexFields::STAGE, Item::Stages::SUBMITTED).
      filter(Item::IndexFields::COLLECTIONS, params[:id]&.gsub(/[^\d]/, "")). # TODO: why does this id sometimes arrive with a comma suffix?
      order(Item::IndexFields::CREATED).
      start(start).
      limit(limit)
  end

  def set_collection
    # N.B.: the `||` supports nested routes.
    @collection = Collection.find(params[:id] || params[:collection_id])
    @breadcrumbable = @collection
  end

  def collection_params
    params.require(:collection).permit(:description, :introduction,
                                       :metadata_profile_id, :parent_id,
                                       :provenance, :rights,
                                       :short_description,
                                       :submission_profile_id,
                                       :submissions_reviewed,
                                       :title, unit_ids: [])
  end

  def set_item_results_ivars
    @permitted_params = params.permit(RESULTS_PARAMS + [:collection_id])
    @start            = @permitted_params[:start].to_i
    @window           = window_size
    @items            = Item.search.
      institution(current_institution).
      aggregations(false).
      metadata_profile(@collection.effective_metadata_profile).
      filter(Item::IndexFields::COLLECTIONS, @permitted_params[:collection_id]).
      # A blank sort means sort by relevance, which is always descending,
      # unlike all other sorts, which default to ascending.
      order(@permitted_params[:sort] =>
              @permitted_params[:sort].blank? ? :desc : @permitted_params[:direction].to_sym).
      start(@start).
      limit(@window)
    process_search_input(@items)

    @items        = policy_scope(@items, policy_scope_class: ItemPolicy::Scope)
    @count        = @items.count
    @current_page = @items.page
  end

end
