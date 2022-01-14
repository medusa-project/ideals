# frozen_string_literal: true

class CollectionsController < ApplicationController

  before_action :ensure_logged_in, only: [:create, :destroy,
                                          :edit_collection_membership,
                                          :edit_managers, :edit_properties,
                                          :edit_submitters,
                                          :edit_unit_membership,
                                          :edit_user_access, :show_access,
                                          :show_review_submissions, :update]
  before_action :set_collection, except: [:create, :index]
  before_action :check_buried, except: [:create, :index]
  before_action :authorize_collection, except: [:create, :index]

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
        order(RegisteredElement.sortable_field(::Configuration.instance.elements[:title])).
        limit(999)
    render partial: "children"
  end

  ##
  # Responds to `POST /collections`.
  #
  def create
    @collection = Collection.new(collection_params)
    authorize @collection
    begin
      ActiveRecord::Base.transaction do
        @collection.primary_unit = Unit.find(params[:primary_unit_id])
        # Save now in order to obtain an ID with which to associate
        # AscribedElements in the next step.
        @collection.save!
        assign_users
        @collection.save!
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @collection.errors.any? ? @collection : e },
             status: :bad_request
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Collection \"#{@collection.title}\" created."
      render 'shared/reload'
    end
  end

  ##
  # Buries--does **not** delete--a collection.
  #
  # Responds to `DELETE /collections/:id`
  #
  def destroy
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
      ElasticsearchClient.instance.refresh
      flash['success'] = "Collection \"#{title}\" deleted."
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
      render plain: "Not Acceptable", status: :not_acceptable
      return
    end
    @start  = results_params[:start].to_i
    @window = window_size
    @collections = Collection.search.
        institution(current_institution).
        aggregations(false).
        query_all(results_params[:q]).
        order(RegisteredElement.sortable_field(::Configuration.instance.elements[:title])).
        start(@start).
        limit(@window)
    @count            = @collections.count
    @current_page     = @collections.page
    @permitted_params = results_params
  end

  ##
  # Renders item download counts by month as HTML and CSV.
  #
  # Responds to `GET /collections/:id/item-download-counts`
  #
  def item_download_counts
    from_time = TimeUtils.ymd_to_time(params[:from_year],
                                      params[:from_month],
                                      params[:from_day])
    to_time   = TimeUtils.ymd_to_time(params[:to_year],
                                      params[:to_month],
                                      params[:to_day])
    @items = @collection.item_download_counts(start_time: from_time,
                                              end_time:   to_time)

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
    review_items  = review_items(0, 0)
    @review_count = review_items.count
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
  # Renders HTML for the collection membership tab in show-collection view.
  #
  # Responds to `GET /collections/:id/collections` (XHR only)
  #
  def show_collections
    @subcollections = Collection.search.
      institution(current_institution).
      parent_collection(@collection).
      include_children(true).
      order(RegisteredElement.sortable_field(::Configuration.instance.elements[:title])).
      limit(999)
    render partial: "show_collections_tab"
  end

  ##
  # Renders HTML for the items tab in show-collection view.
  #
  # Responds to `GET /collections/:id/items`
  #
  def show_items
    set_item_results_ivars
    render partial: "show_items_tab"
  end

  ##
  # Renders HTML for the properties tab in show-collection view.
  #
  # Responds to `GET /collections/:id/properties`
  #
  def show_properties
    @metadata_profile     = @collection.effective_metadata_profile
    @submission_profile   = @collection.effective_submission_profile
    @num_downloads        = @collection.download_count
    @num_submitting_items = @collection.submitted_item_count
    render partial: "show_properties_tab"
  end

  ##
  # Renders HTML for the review submissions tab in show-collection view.
  #
  # Responds to `GET /collections/:id/review-submissions`
  #
  def show_review_submissions
    @review_start            = results_params[:start].to_i
    @review_window           = window_size
    @review_items            = review_items(@review_start, @review_window)
    @review_count            = @review_items.count
    @review_current_page     = @review_items.page
    @review_permitted_params = results_params
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
  # Renders HTML for the unit membership tab in show-collection view.
  #
  # Responds to `GET /collections/:id/units` (XHR only)
  #
  def show_units
    render partial: "show_units_tab"
  end

  ##
  # Renders statistics within a date range as HTML and CSV.
  #
  # Responds to `GET /collections/:id/statistics-by-range`
  #
  def statistics_by_range
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
    downloads_by_month = @collection.download_count_by_month(start_time: from_time,
                                                             end_time:   to_time)
    @counts_by_month.each_with_index do |m, i|
      m['item_count'] = m['count']
      m['dl_count']   = downloads_by_month[i]['dl_count']
      m.delete('count')
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
      ElasticsearchClient.instance.refresh
      flash['success'] = "Collection \"#{@collection.title}\" updated."
      render 'shared/reload'
    end
  end


  private

  def assign_primary_unit
    if params[:primary_unit_id]
      @collection.unit_collection_memberships.destroy_all
      @collection.unit_collection_memberships.build(unit_id: params[:primary_unit_id],
                                                    primary: true)
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
      filter(Item::IndexFields::COLLECTIONS, params[:id]).
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
    @start  = params[:start].to_i
    @window = window_size
    @items  = Item.search.
      institution(current_institution).
      aggregations(false).
      query_all(params[:q]).
      filter(Item::IndexFields::COLLECTIONS, params[:collection_id]).
      order(params[:sort]).
      start(@start).
      limit(@window)
    @items            = policy_scope(@items, policy_scope_class: ItemPolicy::Scope)
    @count            = @items.count
    @current_page     = @items.page
    @permitted_params = params.permit(:q, :start)
  end

end
