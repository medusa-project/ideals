# frozen_string_literal: true

class InstitutionsController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_institution, only: [:destroy, :edit, :item_download_counts,
                                         :show, :statistics,
                                         :statistics_by_range, :update]
  before_action :authorize_institution, only: [:destroy, :edit,
                                               :item_download_counts, :show,
                                               :statistics,
                                               :statistics_by_range, :update]

  ##
  # Responds to `POST /institutions`
  #
  def create
    @institution = Institution.new(institution_params)
    authorize @institution
    begin
      @institution.save!
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @institution },
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
              filename: "#{@institution.key}_download_counts.csv"
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
  # Renders the HTML statistics-aggregation tab content.
  #
  # Responds to `GET /institutions/:key/statistics` (XHR only)
  #
  def statistics
    set_item_download_counts_ivars
    set_statistics_by_range_ivars
    render partial: "show_statistics_tab_content"
  end

  ##
  # Provides statistics within a date range as CSV.
  #
  # Responds to `GET /institutions/:id/statistics-by-range`
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
              filename: "#{@institution.key}_statistics.csv"
  end

  ##
  # Responds to `PATCH /institutions/:key`
  #
  def update
    begin
      @institution.update!(institution_params)
    rescue
      render partial: "shared/validation_messages",
             locals: { object: @institution },
             status: :bad_request
    else
      flash['success'] = "Institution \"#{@institution.name}\" updated."
      render "shared/reload"
    end
  end


  private

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
    params.require(:institution).permit(:default, :fqdn, :key, :name, :org_dn)
  end

  def set_item_download_counts_ivars
    from_time = TimeUtils.ymd_to_time(params[:from_year],
                                      params[:from_month],
                                      params[:from_day])
    to_time   = TimeUtils.ymd_to_time(params[:to_year],
                                      params[:to_month],
                                      params[:to_day])
    @items = @institution.item_download_counts(start_time: from_time,
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
    @counts_by_month = @institution.submitted_item_count_by_month(start_time: from_time,
                                                                  end_time:   to_time)
    downloads_by_month = @institution.download_count_by_month(start_time: from_time,
                                                              end_time:   to_time)

    @counts_by_month.each_with_index do |m, i|
      m['item_count'] = m['count']
      m['dl_count']   = downloads_by_month[i]['dl_count']
      m.delete('count')
    end
  end

end
