# frozen_string_literal: true

class UnitsController < ApplicationController

  include Search

  before_action :ensure_logged_in, only: [:create, :delete,
                                          :edit_administrators,
                                          :edit_membership, :edit_properties,
                                          :show_access, :undelete, :update]
  before_action :set_unit, except: [:create, :index]
  before_action :check_buried, except: [:create, :index, :show, :undelete]
  before_action :authorize_unit, except: [:create, :index]

  ##
  # Renders a partial for the expandable unit list used in {index}. Has the
  # same permissions as {show}.
  #
  # Responds to `GET /units/:unit_id/children` (XHR only)
  #
  def children
    raise ActionController::BadRequest if params[:unit_id].blank?
    @units = Unit.search.
        institution(current_institution).
        filter(Unit::IndexFields::PARENT, params[:unit_id].to_i).
        include_children(true).
        order("#{Unit::IndexFields::TITLE}.sort").
        limit(999)
    render partial: "children"
  end

  ##
  # Renders a JSON list of all of a unit's child collections, except the
  # default. This is used via XHR to build the expandable unit list at
  # `/units`.
  #
  # The permissions are the same as those of {show}.
  #
  # Responds to `GET /units/:unit_id/collections-tree-fragment` (XHR only)
  #
  def collections_tree_fragment
    raise ActionController::BadRequest if params[:unit_id].blank?
    @collections = Collection.search.
        institution(current_institution).
        filter(Collection::IndexFields::PRIMARY_UNIT, @unit.id).
        filter(Collection::IndexFields::UNIT_DEFAULT, false).
        include_children(false).
        order(RegisteredElement.sortable_field(::Configuration.instance.elements[:title])).
        limit(999)
    if params[:'for-select'] == "true"
      render partial: "collections_for_select"
    else
      render partial: "collections/children"
    end
  end

  ##
  # Responds to `POST /units`
  #
  def create
    @unit = Unit.new(unit_params)
    authorize @unit
    begin
      ActiveRecord::Base.transaction do
        @unit.save!
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @unit.errors.any? ? @unit : e },
             status: :bad_request
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Unit \"#{@unit.title}\" created."
      render "create", locals: { unit: @unit }
    end
  end

  ##
  # Buries--does **not** delete--a unit.
  #
  # Responds to `POST /units/:id/delete`
  #
  # @see undelete
  #
  def delete
    ActiveRecord::Base.transaction do
      @unit.bury!
    end
  rescue => e
    flash['error'] = "#{e}"
    redirect_to @unit
  else
    ElasticsearchClient.instance.refresh
    flash['success'] = "Unit \"#{@unit.title}\" deleted."
    redirect_to(@unit.parent || units_path)
  end

  ##
  # Used for editing administrators.
  #
  # Responds to `GET /units/:unit_id/edit-administrators` (XHR only)
  #
  def edit_administrators
    render partial: "units/administrators_form", locals: { unit: @unit }
  end

  ##
  # Used for editing unit membership.
  #
  # Responds to `GET /units/:unit_id/edit-membership` (XHR only)
  #
  def edit_membership
    render partial: "units/membership_form", locals: { unit: @unit }
  end

  ##
  # Used for editing basic properties.
  #
  # Responds to GET `/units/:unit_id/edit` (XHR only)
  #
  def edit_properties
    render partial: "units/properties_form", locals: { unit: @unit }
  end

  ##
  # Responds to `GET /units`
  #
  def index
    @units = Unit.search.
        institution(current_institution).
        include_children(false).
        order("#{Unit::IndexFields::TITLE}.sort").
        limit(9999)
    @new_unit = Unit.new
  end

  ##
  # Renders item download counts by month as HTML and CSV.
  #
  # Responds to `GET /units/:id/item-download-counts`
  #
  def item_download_counts
    from_time = TimeUtils.ymd_to_time(params[:from_year],
                                      params[:from_month],
                                      params[:from_day])
    to_time   = TimeUtils.ymd_to_time(params[:to_year],
                                      params[:to_month],
                                      params[:to_day])
    @items = @unit.item_download_counts(start_time: from_time,
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
                  filename: "unit_#{@unit.id}_download_counts.csv"
      end
    end
  end

  ##
  # Renders results within the items tab in show-unit view.
  #
  # Responds to `GET /units/:id/items`
  #
  def item_results
    set_item_results_ivars
    render partial: "items/listing"
  end

  ##
  # Responds to GET /units/:id
  #
  def show
    if @unit.buried
      render "show_buried", status: :gone and return
    end
    @new_unit = Unit.new
  end

  ##
  # Renders HTML for the access tab in show-unit view.
  #
  # Responds to `GET /units/:id/access`
  #
  def show_access
    render partial: "show_access_tab"
  end

  ##
  # Renders HTML for the collections tab in show-unit view.
  #
  # Responds to `GET /units/:id/collections`
  #
  def show_collections
    @collections = Collection.search.
      institution(current_institution).
      filter(Collection::IndexFields::PRIMARY_UNIT, @unit.id).
      order(RegisteredElement.sortable_field(::Configuration.instance.elements[:title])).
      limit(999)
    render partial: "show_collections_tab"
  end

  ##
  # Renders HTML for the items tab in show-unit view.
  #
  # Responds to `GET /units/:id/items`
  #
  def show_items
    set_item_results_ivars
    respond_to do |format|
      format.html do
        render partial: "show_items_tab"
      end
      format.csv do
        authorize(@unit, policy_method: :export_items)
        send_data(CsvExporter.new.export_unit(@unit),
                  type:        "text/csv",
                  disposition: "attachment",
                  filename:    "unit_#{@unit.id}_items.csv")
      end
    end
  end

  ##
  # Renders HTML for the properties tab in show-unit view.
  #
  # Responds to `GET /units/:id/properties`
  #
  def show_properties
    @num_downloads        = @unit.download_count
    @num_submitting_items = @unit.submitting_item_count
    render partial: "show_properties_tab"
  end

  ##
  # Renders HTML for the statistics tab in show-unit view.
  #
  # Responds to `GET /units/:id/statistics`
  #
  def show_statistics
    render partial: "show_statistics_tab"
  end

  ##
  # Renders HTML for the unit membership tab in show-unit view.
  #
  # Responds to `GET /units/:id/units`
  #
  def show_unit_membership
    @subunits = Unit.search.
      institution(current_institution).
      parent_unit(@unit).
      order("#{Unit::IndexFields::TITLE}.sort").
      limit(999)
    render partial: "show_unit_membership_tab"
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
    @counts_by_month = @unit.submitted_item_count_by_month(start_time: from_time,
                                                           end_time:   to_time)
    downloads_by_month = @unit.download_count_by_month(start_time: from_time,
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
                  filename: "unit_#{@unit.id}_statistics.csv"
      end
    end
  end

  ##
  # Exhumes a buried unit.
  #
  # Responds to `POST /units/:id/undelete`
  #
  # @see delete
  #
  def undelete
    ActiveRecord::Base.transaction do
      @unit.exhume!
    end
  rescue => e
    flash['error'] = "#{e}"
  else
    ElasticsearchClient.instance.refresh
    flash['success'] = "Unit \"#{@unit.title}\" undeleted."
  ensure
    redirect_to @unit
  end

  ##
  # Responds to `PATCH/PUT /units/:id`
  #
  def update
    if params[:unit][:parent_id] &&
        !policy(@unit).change_parent?(params[:unit][:parent_id])
      raise NotAuthorizedError,"Cannot move a unit into a unit of "\
            "which you are not an effective administrator."
    end
    begin
      ActiveRecord::Base.transaction do
        assign_administrators
        @unit.update!(unit_params)
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @unit.errors.any? ? @unit : e },
             status: :bad_request
    else
      ElasticsearchClient.instance.refresh
      flash['success'] = "Unit \"#{@unit.title}\" updated."
      render 'shared/reload'
    end
  end


  private

  def set_unit
    @unit = Unit.find(params[:id] || params[:unit_id])
    @breadcrumbable = @unit
  end

  def authorize_unit
    @unit ? authorize(@unit) : skip_authorization
  end

  def assign_administrators
    # Group administrators
    if params[:user_group_ids]
      @unit.administrator_groups.destroy_all
      params[:user_group_ids].select(&:present?).each do |user_group_id|
        @unit.administrator_groups.build(user_group_id: user_group_id).save!
      end
    end
    # Non-primary user administrators
    if params[:administering_users]
      @unit.administrators.where(primary: false).destroy_all
      params[:administering_users].select(&:present?).each do |user_str|
        user = User.from_autocomplete_string(user_str)
        @unit.errors.add(:administrators,
                             "includes a user that does not exist") unless user
        @unit.administering_users << user
      end
    end
    # Primary user administrator
    if params[:primary_administrator]
      @unit.primary_administrator =
          User.from_autocomplete_string(params[:primary_administrator])
    end
  end

  def check_buried
    raise GoneError if @unit&.buried
  end

  def set_item_results_ivars
    @permitted_params = params.permit(RESULTS_PARAMS + [:unit_id])
    @start            = @permitted_params[:start].to_i
    @window           = window_size
    @items            = Item.search.
      institution(current_institution).
      aggregations(false).
      filter(Item::IndexFields::UNITS, @permitted_params[:unit_id]).
      order(@permitted_params[:sort] => (@permitted_params[:direction] == "desc") ? :desc : :asc).
      start(@start).
      limit(@window)
    process_search_input(@items)

    @items        = policy_scope(@items, policy_scope_class: ItemPolicy::Scope)
    @count        = @items.count
    @current_page = @items.page
  end

  def unit_params
    params.require(:unit).permit(:institution_id, :introduction, :parent_id,
                                 :rights, :short_description, :title)
  end

end
