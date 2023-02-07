# frozen_string_literal: true

class UnitsController < ApplicationController

  include Search

  before_action :ensure_logged_in, only: [:create, :delete,
                                          :edit_administrators,
                                          :edit_membership, :edit_properties,
                                          :show_access, :undelete, :update]
  before_action :set_unit, except: [:create, :index, :new]
  before_action :check_buried, except: [:create, :index, :new, :show, :undelete]
  before_action :authorize_unit, except: [:create, :index]
  before_action :store_location, only: [:index, :show]

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
        order("#{Collection::IndexFields::TITLE}.sort").
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
    @unit             = Unit.new(unit_params)
    @unit.institution = current_institution
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
      RefreshOpensearchJob.perform_later
      toast!(title:   "Unit created",
             message: "The unit \"#{@unit.title}\" has been created.")
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
    RefreshOpensearchJob.perform_later
    toast!(title:   "Unit deleted",
           message: "The unit \"#{@unit.title}\" has been deleted.")
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
  end

  ##
  # Renders item download counts by month as HTML and CSV.
  #
  # Responds to `GET /units/:id/item-download-counts`
  #
  def item_download_counts
    @items = MonthlyItemDownloadCount.unit_download_counts_by_item(
      unit:        @unit,
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
  # Renders the new-unit form. A `parent_id` query argument is supported which
  # will inject a parent unit ID into a hidden form input.
  #
  # Responds to `GET /units/new` (XHR only)
  #
  def new
    @unit = Unit.new
    render partial: "new_form", locals: { parent_id: params[:parent_id] }
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
  # Renders HTML for the properties tab in show-unit view.
  #
  # Responds to `GET /units/:id/about`
  #
  def show_about
    @metadata_profile    = @unit.effective_metadata_profile
    @num_downloads       = MonthlyUnitItemDownloadCount.sum_for_unit(unit: @unit)
    @num_submitted_items = @unit.submitted_item_count
    @collections         = Collection.search.
      institution(current_institution).
      filter(Collection::IndexFields::PRIMARY_UNIT, @unit.id).
      order("#{Collection::IndexFields::TITLE}.sort").
      limit(999)
    @subunits            = Unit.search.
      institution(current_institution).
      parent_unit(@unit).
      order("#{Unit::IndexFields::TITLE}.sort").
      limit(999)
    render partial: "show_about_tab"
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
  # Renders HTML for the statistics tab in show-unit view.
  #
  # Responds to `GET /units/:id/statistics`
  #
  def show_statistics
    render partial: "show_statistics_tab"
  end

  ##
  # Renders statistics within a date range as HTML and CSV.
  #
  # Responds to `GET /units/:id/statistics-by-range`
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
      @counts_by_month = @unit.submitted_item_count_by_month(start_time: from_time,
                                                             end_time:   to_time)
      downloads_by_month = MonthlyUnitItemDownloadCount.for_unit(
        unit:        @unit,
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
    RefreshOpensearchJob.perform_later
    toast!(title:   "Unit undeleted",
           message: "The unit \"#{@unit.title}\" has been undeleted.")
  ensure
    redirect_to @unit
  end

  ##
  # Responds to `PATCH/PUT /units/:id`
  #
  def update
    if params[:unit][:parent_id].present? &&
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
      RefreshOpensearchJob.perform_later
      toast!(title:   "Unit updated",
             message: "The unit \"#{@unit.title}\" has been updated.")
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

  def unit_params
    params.require(:unit).permit(:institution_id, :introduction,
                                 :metadata_profile_id, :parent_id, :rights,
                                 :short_description, :title)
  end

end
