class InstitutionsController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_institution, except: [:create, :index, :new]
  before_action :authorize_institution, except: [:create, :index, :new]
  before_action :store_location, only: [:index, :show]

  ##
  # Responds to `POST /institutions`
  #
  def create
    @institution = Institution.new(institution_params)
    authorize @institution
    begin
      @institution.save!
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @institution.errors.any? ? @institution : e },
             status: :bad_request
    else
      flash['success'] = "Institution \"#{@institution.name}\" created."
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /institutions/:key`
  #
  def destroy
    begin
      @institution.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      flash['success'] = "Institution \"#{@institution.name}\" deleted."
    ensure
      redirect_to institutions_path
    end
  end

  ##
  # Responds to `GET /institutions/:key/edit`
  #
  def edit
    render partial: "institutions/form",
           locals: { institution: @institution }
  end

  ##
  # Used for editing administrators.
  #
  # Responds to `GET /institutions/:key/edit-administrators` (XHR only)
  #
  def edit_administrators
    render partial: "administrators_form", locals: { institution: @institution }
  end

  ##
  # Used for editing the theme.
  #
  # Responds to `GET /institutions/:key/edit-theme` (XHR only)
  #
  def edit_theme
    render partial: "theme_form", locals: { institution: @institution }
  end

  ##
  # Responds to `GET /institutions`
  #
  def index
    authorize Institution
    @institutions    = Institution.all.order(:name)
    @count           = @institutions.count
    @new_institution = Institution.new
  end

  ##
  # Renders a CSV of item download counts by month.
  #
  # Responds to `GET /institutions/:key/item-download-counts`
  #
  def item_download_counts
    @items = MonthlyItemDownloadCount.institution_download_counts_by_item(
      institution: @institution,
      start_year:  params[:from_year].to_i,
      start_month: params[:from_month].to_i,
      end_year:    params[:to_year].to_i,
      end_month:   params[:to_month].to_i)

    # The items array contains item IDs and download counts but not titles.
    # So here we will insert them.
    AscribedElement.
      where(registered_element: RegisteredElement.find_by_name("dc:title")).
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
                  filename: "#{@institution.key}_download_counts.csv"
      end
    end
  end

  ##
  # Responds to `GET /institutions/new`
  #
  def new
    @institution = Institution.new
    authorize @institution
    render partial: "institutions/form",
           locals: { institution: @institution }
  end

  ##
  # Responds to `GET /institutions/:key`
  #
  def show
  end

  ##
  # Renders HTML for the access tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/access`
  #
  def show_access
    render partial: "show_access_tab"
  end

  ##
  # Renders HTML for the properties tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/properties` (XHR only)
  #
  def show_properties
    render partial: "show_properties_tab"
  end

  ##
  # Renders HTML for the statistics tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/statistics` (XHR only)
  #
  def show_statistics
    render partial: "show_statistics_tab"
  end

  ##
  # Renders HTML for the theme tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/theme` (XHR only)
  #
  def show_theme
    render partial: "show_theme_tab"
  end

  ##
  # Renders HTML for the users tab in show-institution view.
  #
  # Responds to `GET /institutions/:key/users` (XHR only)
  #
  def show_users
    render partial: "show_users_tab"
  end

  ##
  # Provides statistics within a date range as CSV.
  #
  # Responds to `GET /institutions/:key/statistics-by-range`
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
    @counts_by_month = @institution.submitted_item_count_by_month(start_time: from_time,
                                                                  end_time:   to_time)
    downloads_by_month = MonthlyInstitutionItemDownloadCount.for_institution(
      institution: @institution,
      start_year:  params[:from_year].to_i,
      start_month: params[:from_month].to_i,
      end_year:    params[:to_year].to_i,
      end_month:   params[:to_month].to_i)

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
                  filename: "#{@institution.key}_statistics.csv"
      end
    end
  end

  ##
  # Responds to `PATCH /institutions/:key`
  #
  def update
    begin
      ActiveRecord::Base.transaction do
        assign_administrators
        upload_images
        @institution.update!(institution_params)
      end
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @institution.errors.any? ? @institution : e },
             status: :bad_request
    else
      flash['success'] = "Institution \"#{@institution.name}\" updated."
      render "shared/reload"
    end
  end


  private

  def assign_administrators
    # Group administrators
    if params[:user_group_ids]
      @institution.administrator_groups.destroy_all
      params[:user_group_ids].select(&:present?).each do |user_group_id|
        @institution.administrator_groups.build(user_group_id: user_group_id).save!
      end
    end
    # User administrators
    if params[:administering_users]
      @institution.administrators.destroy_all
      params[:administering_users].select(&:present?).each do |user_str|
        user = User.from_autocomplete_string(user_str)
        @institution.errors.add(:administrators,
                                "includes a user that does not exist") unless user
        @institution.administering_users << user
      end
    end
  end

  def set_institution
    @institution = Institution.find_by_key(params[:key] || params[:institution_key])
    raise ActiveRecord::RecordNotFound unless @institution
    @breadcrumbable = @institution
  end

  def authorize_institution
    @institution ? authorize(@institution) : skip_authorization
  end

  def institution_params
    # Key and name are accepted during creation. For updates, they are
    # overwritten by the contents of org_dn.
    params.require(:institution).permit(:active_link_color, :default,
                                        :feedback_email,
                                        :footer_background_color,
                                        :fqdn, :header_background_color,
                                        :key, :link_color, :link_hover_color,
                                        :main_website_url, :name, :org_dn,
                                        :primary_color, :primary_hover_color,
                                        :welcome_html)
  end

  def upload_images
    p = params[:institution]
    if p[:banner_image]
      @institution.upload_banner_image(io:        p[:banner_image],
                                       extension: p[:banner_image].original_filename.split(".").last)
    end
    if p[:footer_image]
      @institution.upload_footer_image(io:        p[:footer_image],
                                       extension: p[:footer_image].original_filename.split(".").last)
    end
    if p[:header_image]
      @institution.upload_header_image(io:        p[:header_image],
                                       extension: p[:header_image].original_filename.split(".").last)
    end
  end

end
