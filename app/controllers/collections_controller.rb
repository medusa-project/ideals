# frozen_string_literal: true

class CollectionsController < ApplicationController

  before_action :ensure_logged_in, except: [:children, :index, :show]
  before_action :set_collection, only: [:children, :destroy, :edit_access,
                                        :edit_collection_membership,
                                        :edit_properties, :edit_unit_membership,
                                        :item_download_counts, :show,
                                        :statistics, :statistics_by_range,
                                        :update]
  before_action :authorize_collection, only: [:destroy, :edit_access,
                                              :edit_collection_membership,
                                              :edit_properties,
                                              :edit_unit_membership,
                                              :item_download_counts, :show,
                                              :statistics, :statistics_by_range,
                                              :update]

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
        build_metadata
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
  # Responds to `DELETE /collections/:id`
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
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Collection \"#{title}\" deleted."
    ensure
      redirect_to(parent || primary_unit)
    end
  end

  ##
  # Used for editing access control.
  #
  # Responds to `GET /collections/:id/edit-membership` (XHR only)
  #
  def edit_access
    render partial: 'collections/access_form',
           locals: { collection: @collection }
  end

  ##
  # Used for editing collection membership.
  #
  # Responds to `GET /collections/:id/edit-collection-membership` (XHR only)
  #
  def edit_collection_membership
    render partial: 'collections/collection_membership_form',
           locals: { collection: @collection }
  end

  ##
  # Used for editing basic properties.
  #
  # Responds to GET `/collections/:id/edit` (XHR only)
  #
  def edit_properties
    render partial: 'collections/properties_form',
           locals: { collection: @collection }
  end

  ##
  # Used for editing unit membership.
  #
  # Responds to `GET /collections/:id/edit-unit-membership` (XHR only)
  #
  def edit_unit_membership
    render partial: 'collections/unit_membership_form',
           locals: { collection: @collection,
                     primary_unit: @collection.primary_unit }
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
  # Provides item download counts within a date range as CSV.
  #
  # Responds to `GET /collections/:id/item-download-counts`
  #
  def item_download_counts
    set_item_download_counts_ivars
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

  ##
  # Responds to `GET /collections/:id`
  #
  def show
    @start  = params[:start].to_i
    @window = window_size
    @items  = Item.search.
        institution(current_institution).
        aggregations(false).
        filter(Item::IndexFields::COLLECTIONS, params[:id]).
        order(params[:sort]).
        start(@start).
        limit(@window)
    @items            = policy_scope(@items, policy_scope_class: ItemPolicy::Scope)
    @count            = @items.count
    @current_page     = @items.page
    @permitted_params = params.permit(:q, :start)

    # Properties tab
    @num_downloads        = @collection.download_count
    @num_submitting_items = @collection.submitted_item_count

    # Metadata tab
    @metadata_profile   = @collection.effective_metadata_profile
    @submission_profile = @collection.effective_submission_profile

    # Subcollections tab
    @subcollections = Collection.search.
        institution(current_institution).
        parent_collection(@collection).
        include_children(true).
        order(RegisteredElement.sortable_field(::Configuration.instance.elements[:title])).
        limit(999)

    # Review Submissions tab
    @review_start  = results_params[:start].to_i
    @review_window = window_size
    @review_items  = Item.search.
        institution(current_institution).
        aggregations(false).
        filter(Item::IndexFields::STAGE, Item::Stages::SUBMITTED).
        filter(Item::IndexFields::COLLECTIONS, params[:id]).
        order(Item::IndexFields::CREATED).
        start(@review_start).
        limit(@review_window)
    @review_count            = @review_items.count
    @review_current_page     = @review_items.page
    @review_permitted_params = results_params
  end

  ##
  # Renders the HTML statistics-aggregation tab content.
  #
  # Responds to `GET /collections/:id/statistics` (XHR only)
  #
  def statistics
    set_item_download_counts_ivars
    set_statistics_by_range_ivars
    render partial: "show_statistics_tab_content"
  end

  ##
  # Provides statistics within a date range as CSV.
  #
  # Responds to `GET /collections/:id/statistics-by-range`
  #
  def statistics_by_range
    set_statistics_by_range_ivars
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

  ##
  # Responds to `PATCH/PUT /collections/:id`
  #
  def update
    if params[:collection] && params[:collection][:parent_id] &&
        !policy(@collection).change_parent?(params[:collection][:parent_id])
      raise Pundit::NotAuthorizedError,"Cannot move a collection into a "\
            "collection of which you are not an effective manager."
    end
    begin
      ActiveRecord::Base.transaction do
        assign_users
        build_metadata
        if params[:primary_unit_id]
          @collection.unit_collection_memberships.destroy_all
          @collection.unit_collection_memberships.build(unit_id: params[:primary_unit_id],
                                                        primary: true)
        end
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

  def assign_users
    # Managers
    if params[:managers].present?
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
    if params[:submitters].present?
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

  ##
  # Builds and ascribes {AscribedElement}s to the collection based on user
  # input. This is done manually because to do it using Rails nested attributes
  # would be a PITA.
  #
  def build_metadata
    if params[:elements].present?
      config                  = ::Configuration.instance
      reg_title_element       = RegisteredElement.find_by_name(config.elements[:title])
      reg_description_element = RegisteredElement.find_by_name(config.elements[:description])

      # Remove existing title & description
      @collection.elements.where(registered_element_id: [reg_title_element.id,
                                                         reg_description_element.id]).destroy_all
      # Add title
      title = params[:elements][config.elements[:title]]
      @collection.elements.build(registered_element: reg_title_element,
                                 string: title) if title.present?
      # Add description
      description = params[:elements][config.elements[:description]]
      @collection.elements.build(registered_element: reg_description_element,
                                 string: description) if description.present?
    end
  end

  def set_collection
    # N.B.: the `||` supports nested routes.
    @collection = Collection.find(params[:id] || params[:collection_id])
    @breadcrumbable = @collection
  end

  def authorize_collection
    @collection ? authorize(@collection) : skip_authorization
  end

  def collection_params
    params.require(:collection).permit(:metadata_profile_id, :parent_id,
                                       :submission_profile_id,
                                       :submissions_reviewed,
                                       unit_ids: [])
  end

  def set_item_download_counts_ivars
    from_time = TimeUtils.ymd_to_time(params[:from_year],
                                      params[:from_month],
                                      params[:from_day])
    to_time   = TimeUtils.ymd_to_time(params[:to_year],
                                      params[:to_month],
                                      params[:to_day])
    @items = @collection.item_download_counts(start_time: from_time,
                                              end_time:   to_time)
  end

  def set_statistics_by_range_ivars
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
  end

end
