# frozen_string_literal: true

class IndexPagesController < ApplicationController

  before_action :ensure_institution_host
  before_action :ensure_logged_in, except: :show
  before_action :set_index_page, except: [:create, :index, :new]
  before_action :authorize_index_page, except: [:create, :index, :new]
  before_action :store_location, only: [:index, :show]

  ##
  # Responds to `POST /index-pages`
  #
  def create
    authorize IndexPage
    @index_page = IndexPage.new(sanitized_params)
    begin
      assign_elements
      @index_page.save!
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @index_page.errors.any? ? @index_page : e },
             status: :bad_request
    else
      toast!(title:   "Index page created",
             message: "Index page \"#{@index_page.name}\" has been created.")
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /index-pages/:id`
  #
  def destroy
    institution = @index_page.institution
    begin
      @index_page.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      toast!(title:   "Index page deleted",
             message: "Index page \"#{@index_page.name}\" has been deleted.")
    ensure
      if current_user_is_sysadmin?
        redirect_to institution_path(institution)
      else
        redirect_to index_pages_path
      end
    end
  end

  ##
  # Returns content for the edit-index-page form.
  #
  # Responds to `GET /index-pages/:id/edit` (XHR only)
  #
  def edit
    render partial: "form"
  end

  ##
  # Responds to `GET /index-pages`
  #
  def index
    authorize IndexPage
    @index_pages = IndexPage.
      where(institution: current_institution).
      order(:name)
  end

  ##
  # Returns content for the create-index-page form.
  #
  # Responds to `GET /index-pages/new` (XHR only)
  #
  # The following query arguments are accepted:
  #
  # * `institution_id`: ID of the owning institution.
  #
  def new
    authorize IndexPage
    if params.dig(:index_page, :institution_id).blank?
      render plain: "Missing institution ID", status: :bad_request
      return
    end
    @index_page = IndexPage.new(sanitized_params)
    render partial: "form"
  end

  ##
  # Responds to `GET /index-pages/:id`
  #
  def show
    @permitted_params = params.permit(:letter, :q, :start)
    @start            = @permitted_params[:start].to_i.abs
    @window           = 50
    reg_e_ids         = @index_page.registered_element_ids
    if reg_e_ids.any?
      @count            = term_count(reg_e_ids)
      @terms            = terms(reg_e_ids, @start, @window)
      @current_page     = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
      # This may give us a little performance boost
      @starting_chars = Rails.cache.fetch("index_page_#{@index_page.id} starting_chars",
                                            expires_in: 1.hour) do
        starting_chars(reg_e_ids)
      end
    else
      @count          = 0
      @current_page   = 1
      @terms          = []
      @starting_chars = []
    end
    @breadcrumbable = @index_page
  end

  ##
  # Responds to `PUT/PATCH /index-pages/:id`
  #
  def update
    begin
      assign_elements
      @index_page.update!(sanitized_params)
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @index_page.errors.any? ? @index_page : e },
             status: :bad_request
    else
      toast!(title:   "Index page updated",
             message: "Index page \"#{@index_page.name}\" has been updated.")
      render "shared/reload"
    end
  end


  private

  def sanitized_params
    params.require(:index_page).permit(:institution_id, :name)
  end

  def set_index_page
    @index_page = IndexPage.find(params[:id] || params[:index_page_id])
  end

  def authorize_index_page
    @index_page ? authorize(@index_page) : skip_authorization
  end

  def assign_elements
    if params[:registered_element_ids]&.respond_to?(:each)
      @index_page.registered_element_ids = params[:registered_element_ids].select(&:present?)
    end
  end

  def starting_chars(reg_e_ids)
    # This query doesn't take embargoes into account because doing so would
    # make it a lot slower. We assume that there are so few embargoed items
    # with distinct starting characters that it will practically never matter.
    sql = "SELECT alpha, count
    FROM (
      SELECT DISTINCT(UNACCENT(UPPER(SUBSTR(string, 1, 1)))) AS alpha,
        COUNT(ae.id) AS count
      FROM ascribed_elements ae
      INNER JOIN items i ON i.id = ae.item_id
      WHERE i.institution_id = $1
        AND i.stage = $2
        AND ae.registered_element_id IN (#{reg_e_ids.join(",")})
      GROUP BY alpha
    ) t
    WHERE count > 0
    ORDER BY (alpha ~ '\\d')::int, alpha;"
    values = [current_institution.id, Item::Stages::APPROVED]
    ActiveRecord::Base.connection.exec_query(sql, "SQL", values)
  end

  def term_count(reg_e_ids)
    values = [current_institution.id, Item::Stages::APPROVED]
    # This query includes terms from embargoed items because taking those
    # into account would greatly slow it down. We assume that there
    # are few enough embargoed items that it isn't going to matter much.
    sql = "SELECT COUNT(DISTINCT(string)) AS count
          FROM ascribed_elements ae
          INNER JOIN items i ON i.id = ae.item_id
          WHERE i.institution_id = $1
            AND i.stage = $2
            AND ae.registered_element_id IN (#{reg_e_ids.join(",")}) "
    # N.B.: attackers are known to attempt SQL injections here, which will
    # cause a flood of ArgumentError emails unless we rescue.
    begin
      if params[:letter]
        sql += "AND UNACCENT(LOWER(string)) LIKE $3 "
        values << "#{params[:letter].downcase}%"
      elsif params[:q]
        sql += "AND UNACCENT(LOWER(string)) LIKE $3 "
        values << "%#{params[:q].downcase}%"
      end
    rescue ArgumentError => e
      if e.message.include?("string contains null byte")
        raise ActionDispatch::Http::Parameters::ParseError
      else
        raise e
      end
    end
    ActiveRecord::Base.connection.exec_query(sql, "SQL", values)[0]['count']
  end

  def terms(reg_e_ids, start, window)
    values = [current_institution.id, Item::Stages::APPROVED]
    # This query includes terms from embargoed items because taking those
    # into account would greatly slow it down. We assume that there
    # are few enough embargoed items that it isn't going to matter much.
    sql = "SELECT string
            FROM (
              SELECT DISTINCT(string) AS string
              FROM ascribed_elements ae
              INNER JOIN items i ON i.id = ae.item_id
              WHERE i.institution_id = $1
                AND i.stage = $2
                AND ae.registered_element_id IN (#{reg_e_ids.join(",")}) "
    # N.B.: attackers are known to attempt SQL injections here, which will
    # cause a flood of ArgumentError emails unless we rescue.
    begin
      if params[:letter]
        sql += "AND UNACCENT(LOWER(string)) LIKE $3 "
        values << "#{params[:letter].downcase}%"
      elsif params[:q]
        sql += "AND UNACCENT(LOWER(string)) LIKE $3 "
        values << "%#{params[:q].downcase}%"
      end
    rescue ArgumentError => e
      if e.message.include?("string contains null byte")
        raise ActionDispatch::Http::Parameters::ParseError
      else
        raise e
      end
    end
    sql += ") t
            ORDER BY (string ~ '\\d')::int, string
            OFFSET #{start}
            LIMIT #{window};"
    ActiveRecord::Base.connection.exec_query(sql, "SQL", values).map{ |r| r['string'] }
  end

end
