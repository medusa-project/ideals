# frozen_string_literal: true

class CollectionsController < ApplicationController

  include Search

  before_action :ensure_institution_host
  before_action :ensure_logged_in, only: [:all_files, :bury, :create, :destroy,
                                          :edit_administering_groups,
                                          :edit_administering_users,
                                          :edit_collection_membership,
                                          :edit_properties,
                                          :edit_submitting_groups,
                                          :edit_submitting_users,
                                          :edit_unit_membership,
                                          :edit_user_access, :exhume, :new,
                                          :show_access,
                                          :show_review_submissions, :update]
  before_action :set_collection, except: [:create, :index, :new]
  before_action :redirect_scope, only: :show
  before_action :check_buried, except: [:create, :exhume, :index, :new, :show]
  before_action :authorize_collection, except: [:create, :index, :new]
  before_action :store_location, only: [:index, :show]

  ##
  # Responds to `GET /collections/:collection_id/all-files`
  #
  def all_files
    respond_to do |format|
      format.zip do
        collection_ids = [@collection.id] + @collection.all_child_ids
        item_ids       = policy_scope(Item.search.filter(Item::IndexFields::COLLECTIONS, collection_ids),
                                      policy_scope_class: ItemPolicy::Scope).to_id_a
        if item_ids.any?
          download = Download.create!(institution: @collection.institution,
                                      ip_address:  request.remote_ip)
          task     = Task.create!(name: ZipItemsJob.to_s)
          ZipItemsJob.perform_later(item_ids:         item_ids.map{ |h| h[:id] },
                                    metadata_profile: @collection.institution.default_metadata_profile,
                                    download:         download,
                                    user:             current_user,
                                    request_context:  request_context,
                                    task:             task)
          redirect_to download_url(download)
        else
          head :no_content
        end
      end
    end
  end

  ##
  # "Buries" (does **not** delete) a collection.
  #
  # Burial is an incomplete form of deletion that leaves behind a tombstone
  # record. Buried collections can be {exhume exhumed}.
  #
  # Responds to `POST /collections/:id/bury`
  #
  # @see exhume
  #
  def bury
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
             message: "The collection \"#{title}\" has been deleted.")
      redirect_to(parent || primary_unit)
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
        institution(@collection.institution).
        filter(Collection::IndexFields::PARENT, @collection.id).
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
        @collection.primary_unit = Unit.find_by_id(params[:primary_unit_id])
        # We need to save now in order to assign the collection an ID which
        # many of the authorization methods will need. If authorization fails,
        # the transaction will roll back.
        CreateCollectionCommand.new(user:       current_user,
                                    collection: @collection).execute
        authorize @collection
      end
    rescue NotAuthorizedError => e
      raise e
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @collection.errors.any? ? @collection : e },
             status: :bad_request
    else
      # refresh now so that the response contains a current list
      OpenSearchClient.instance.refresh
      toast!(title:   "Collection created",
             message: "The collection \"#{@collection.title}\" has been created.")
      render "shared/reload"
    end
  end

  ##
  # Permanently deletes a collection.
  #
  # Responds to `DELETE /collections/:id`
  #
  # @see bury
  #
  def destroy
    primary_unit = @collection.primary_unit
    parent       = @collection.parent
    title        = @collection.title
    begin
      ActiveRecord::Base.transaction do
        @collection.destroy!
      end
    rescue => e
      flash['error'] = "#{e}"
      redirect_to @collection
    else
      RefreshOpensearchJob.perform_later
      toast!(title:   "Collection deleted",
             message: "The collection \"#{title}\" has been deleted.")
      redirect_to(parent || primary_unit)
    end
  end

  ##
  # Responds to `GET /collections/:collection_id/edit-administering-groups`
  # (XHR only)
  #
  def edit_administering_groups
    render partial: "collections/administering_groups_form",
           locals: { collection: @collection }
  end

  ##
  # Responds to `GET /collections/:collection_id/edit-administering-users`
  # (XHR only)
  #
  def edit_administering_users
    render partial: "collections/administering_users_form",
           locals: { collection: @collection }
  end

  ##
  # Responds to `GET /collections/:collection_id/edit-collection-membership`
  # (XHR only)
  #
  def edit_collection_membership
    render partial: "collections/collection_membership_form",
           locals: { collection: @collection }
  end

  ##
  # Responds to GET `/collections/:collection_id/edit-properties` (XHR only)
  #
  def edit_properties
    render partial: "collections/properties_form",
           locals: { collection: @collection }
  end

  ##
  # Responds to `GET /collections/:collection_id/edit-submitting-groups`
  # (XHR only)
  #
  def edit_submitting_groups
    render partial: "collections/submitting_groups_form",
           locals: { collection: @collection }
  end

  ##
  # Responds to `GET /collections/:collection_id/edit-submitting-users`
  # (XHR only)
  #
  def edit_submitting_users
    render partial: "collections/submitting_users_form",
           locals: { collection: @collection }
  end

  ##
  # Responds to `GET /collections/:id/edit-unit-membership` (XHR only)
  #
  def edit_unit_membership
    render partial: "collections/unit_membership_form",
           locals: { collection: @collection,
                     primary_unit: @collection.primary_unit }
  end

  ##
  # Responds to `GET /collections/:id/edit-user-access` (XHR only)
  #
  def edit_user_access
    render partial: "collections/user_access_form",
           locals: { collection: @collection }
  end

  ##
  # Exhumes/un-buries a buried collection.
  #
  # Responds to `POST /collections/:id/exhume`
  #
  # @see bury
  #
  def exhume
    ActiveRecord::Base.transaction do
      @collection.exhume!
    end
  rescue => e
    flash['error'] = "#{e}"
  else
    RefreshOpensearchJob.perform_later
    toast!(title:   "Collection undeleted",
           message: "The collection \"#{@collection.title}\" has been undeleted.")
  ensure
    redirect_to @collection
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
    @start            = [@permitted_params[:start].to_i.abs, MAX_START].min
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
      where(registered_element: @collection.institution.title_element).
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
  # N.B.: the following query arguments are accepted:
  #
  # * `institution_id`:  ID of the owning institution.
  # * `primary_unit_id`: ID of the primary unit.
  # * `parent_id`:       ID of a parent collection (optional).
  #
  # Responds to `GET /collections/new`
  #
  def new
    if params[:primary_unit_id].blank?
      render plain: "Missing primary unit ID", status: :bad_request
      return
    elsif params.dig(:collection, :institution_id).blank?
      render plain: "Missing institution ID", status: :bad_request
      return
    end
    @collection              = Collection.new(collection_params)
    @collection.primary_unit = Unit.find_by_id(params[:primary_unit_id])
    authorize(@collection)
    render partial: "new_form", locals: {
      institution:  @collection.institution,
      primary_unit: @collection.primary_unit,
      parent:       @collection.parent
    }
  end

  ##
  # Responds to `GET /collections/:id`
  #
  def show
    if @collection.buried
      render "show_buried", status: :gone and return
    end
    @review_count                  = review_items(0, 0).count
    @submissions_in_progress_count = submissions_in_progress(0, 0).count
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
      institution(@collection.institution).
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
  # Renders HTML for the submissions-in-progress tab in show-collection view.
  #
  # Responds to `GET /collections/:id/submissions-in-progress`
  #
  def show_submissions_in_progress
    @permitted_params = params.permit(Search::RESULTS_PARAMS)
    @start            = [@permitted_params[:start].to_i.abs, MAX_START].min
    @window           = window_size
    @items            = submissions_in_progress(@start, @window)
    @count            = @items.count
    @current_page     = @items.page
    render partial: "show_submissions_in_progress_tab"
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
  # Responds to `PATCH/PUT /collections/:id`
  #
  def update
    if params[:collection] && params[:collection][:parent_id] &&
        !policy(@collection).change_parent?(params[:collection][:parent_id])
      raise NotAuthorizedError,"Cannot move a collection into a "\
            "collection of which you are not an effective administrator."
    end
    begin
      ActiveRecord::Base.transaction do
        UpdateCollectionCommand.new(user:       current_user,
                                    collection: @collection).execute do
          assign_users
          assign_user_groups
          assign_primary_unit
          @collection.update!(collection_params)
        end
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @collection.errors.any? ? @collection : e },
             status: :bad_request
    else
      RefreshOpensearchJob.perform_later
      toast!(title:   "Collection updated",
             message: "The collection \"#{@collection.title}\" has been updated.")
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
    # Administrators
    if params[:administering_user_group_ids]
      @collection.administrator_groups.destroy_all
      params[:administering_user_group_ids].select(&:present?).each do |user_group_id|
        @collection.administrator_groups.build(user_group_id: user_group_id).save!
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
    # Administrators
    if params[:administrators]
      @collection.administrators.destroy_all
      if params[:administrators].respond_to?(:each)
        params[:administrators].select(&:present?).each do |user_str|
          user = User.from_autocomplete_string(user_str)
          @collection.errors.add(:administrators,
                               "includes a user that does not exist") unless user
          @collection.administering_users << user
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
      institution(@collection.institution).
      aggregations(false).
      filter(Item::IndexFields::STAGE, Item::Stages::SUBMITTED).
      filter(Item::IndexFields::COLLECTIONS, @collection.id).
      order(Item::IndexFields::CREATED).
      start(start).
      limit(limit)
  end

  def submissions_in_progress(start, limit)
    Item.search.
      institution(@collection.institution).
      aggregations(false).
      filter(Item::IndexFields::STAGE, Item::Stages::SUBMITTING).
      filter(Item::IndexFields::COLLECTIONS, @collection.id).
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
    params.require(:collection).permit(:accepts_submissions, :description,
                                       :introduction, :institution_id,
                                       :metadata_profile_id, :parent_id,
                                       :provenance, :rights,
                                       :short_description,
                                       :submission_profile_id,
                                       :submissions_reviewed,
                                       :title, unit_ids: [])
  end

  ##
  # This action works differently depending on whether the current user is a
  # system administrator:
  #
  # * If the current user **is not** a system administrator, and the client is
  #   trying to access a collection via a different institution's host, this
  #   action redirects to the same path on the collection's host. (Without this
  #   action in place, 403 Forbidden would be returned.) This feature prevents
  #   breakage of external links to collections that have been moved to a
  #   different institution (via {Unit#move_to}).
  # * If the current user **is** a system administrator, this action does
  #   nothing. This is because system administrators require the ability to
  #   browse other institutions' collections within their own institutional
  #   host scope.
  #
  def redirect_scope
    if @collection.institution != current_institution && !current_user_is_sysadmin?
      scheme = (Rails.env.development? || Rails.env.test?) ? "http" : "https"
      redirect_to scheme + "://" + @collection.institution.fqdn + collection_path(@collection),
                  allow_other_host: true
    end
  end

  def set_item_results_ivars
    @permitted_params = params.permit(RESULTS_PARAMS + [:collection_id])
    @start            = [@permitted_params[:start].to_i.abs, MAX_START].min
    @window           = window_size
    @items            = Item.search.
      institution(@collection.institution).
      aggregations(false).
      metadata_profile(@collection.effective_metadata_profile).
      filter(Item::IndexFields::COLLECTIONS, @permitted_params[:collection_id]).
      # A blank sort means sort by relevance, which is always descending,
      # unlike all other sorts, which default to ascending.
      order(@permitted_params[:sort] =>
              @permitted_params[:sort].blank? ? :desc : @permitted_params[:direction].to_sym).
      start(@start).
      limit(@window)
    process_search_query(@items)

    @items        = policy_scope(@items, policy_scope_class: ItemPolicy::Scope)
    @count        = @items.count
    @current_page = @items.page
  end

end
