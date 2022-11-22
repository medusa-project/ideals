class IndexPagesController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_index_page, except: [:create, :index, :new]
  before_action :authorize_index_page, except: [:create, :index, :new]
  before_action :store_location, only: [:index, :show]

  ##
  # Responds to `POST /index-pages`
  #
  def create
    authorize IndexPage
    @index_page             = IndexPage.new(sanitized_params)
    @index_page.institution = current_institution
    begin
      assign_elements
      @index_page.save!
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @index_page.errors.any? ? @index_page : e },
             status: :bad_request
    else
      flash['success'] = "Index page \"#{@index_page.name}\" created."
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /index-pages/:id`
  #
  def destroy
    begin
      @index_page.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      flash['success'] = "Index page \"#{@index_page.name}\" deleted."
    ensure
      redirect_to index_pages_path
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
  def new
    authorize IndexPage
    @index_page = IndexPage.new
    render partial: "form"
  end

  ##
  # Responds to `GET /index-pages/:id`
  #
  def show
    @permitted_params = params.permit(:letter, :start)
    @start            = @permitted_params[:start].to_i
    @window           = 50
    reg_e_ids         = @index_page.registered_element_ids
    if reg_e_ids.any?
      # This query includes terms from embargoed items because taking those
      # into account would greatly slow it down. We assume that there
      # are few enough embargoed items that it isn't going to matter much.
      @terms            = AscribedElement.
        select(:string).
        distinct.
        joins(:item).
        where("items.institution_id": current_institution.id,
              "items.stage":          Item::Stages::APPROVED,
              registered_element_id:  reg_e_ids).
        order(:string)
      if params[:letter]
        @terms = @terms.where("LOWER(string) LIKE ?", "#{params[:letter].downcase}%")
      end
      @count            = @terms.count
      @terms            = @terms.offset(@start).
        limit(@window).
        pluck(:string)
      @current_page     = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
      # This may give us a little performance boost
      @starting_letters = Rails.cache.fetch("index_page_#{@index_page.id} starting_letters",
                                            expires_in: 10.minutes) do
        starting_letters(reg_e_ids)
      end
    else
      @count            = 0
      @current_page     = 1
      @terms            = []
      @starting_letters = []
    end
    @breadcrumbable   = @index_page
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
      flash['success'] = "Index page \"#{@index_page.name}\" updated."
      render "shared/reload"
    end
  end


  private

  def sanitized_params
    params.require(:index_page).permit(:name)
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

  def starting_letters(reg_e_ids)
    # This query doesn't take embargoes into account because doing so would
    # make it a lot slower. We assume that there are so few embargoed items
    # with distinct starting letters that it's hardly ever going to matter.
    sql = "SELECT UPPER(SUBSTR(string, 1, 1)) AS alpha, COUNT(ascribed_elements.id)
    FROM ascribed_elements
    INNER JOIN items i ON i.id = ascribed_elements.item_id
    WHERE i.institution_id = #{current_institution.id}
      AND i.stage = #{Item::Stages::APPROVED}
      AND ascribed_elements.registered_element_id IN (#{reg_e_ids.join(",")})
    GROUP BY UPPER(SUBSTR(string, 1, 1))
    ORDER BY UPPER(SUBSTR(string, 1, 1));"
    results = ActiveRecord::Base.connection.execute(sql)
    results.select{ |row| row['count'] > 0 }
  end

end
