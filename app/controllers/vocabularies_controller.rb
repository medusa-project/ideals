# frozen_string_literal: true

class VocabulariesController < ApplicationController

  before_action :ensure_institution_host, :ensure_logged_in
  before_action :set_vocabulary, except: [:create, :index, :new]
  before_action :authorize_vocabulary, except: [:create, :index]
  before_action :store_location, only: [:index, :show]

  ##
  # Responds to `POST /vocabularies`
  #
  def create
    @vocabulary = Vocabulary.new(vocabulary_params)
    authorize @vocabulary
    begin
      @vocabulary.save!
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @vocabulary.errors.any? ? @vocabulary : e },
             status: :bad_request
    else
      toast!(title:   "Vocabulary created",
             message: "The vocabulary \"#{@vocabulary.name}\" has been created.")
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /vocabularies/:id`
  #
  def destroy
    institution = @vocabulary.institution
    begin
      @vocabulary.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      toast!(title:   "Vocabulary deleted",
             message: "The vocabulary \"#{@vocabulary.name}\" has been deleted.")
    ensure
      if current_user.sysadmin?
        redirect_to institution_path(institution)
      else
        redirect_to vocabularies_path
      end
    end
  end

  ##
  # Responds to `GET /vocabularies/:id/edit`
  #
  def edit
    render partial: "vocabularies/form",
           locals: { vocabulary: @vocabulary }
  end

  ##
  # Responds to `GET /vocabularies`
  #
  def index
    authorize(Vocabulary)
    @permitted_params = params.permit(Search::RESULTS_PARAMS +
                                        Search::SIMPLE_SEARCH_PARAMS +
                                        [:institution_id])
    @start            = [@permitted_params[:start].to_i.abs, MAX_START].min
    @window           = window_size
    @vocabularies     = Vocabulary.
      where(institution: current_institution).
      order(:name)
    @count            = @vocabularies.count
    @vocabularies     = @vocabularies.limit(@window).offset(@start)
    @current_page     = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
  end

  ##
  # Responds to `GET /vocabularies/new`
  #
  # The following query arguments are accepted:
  #
  # * `institution_id`: ID of the owning institution.
  #
  def new
    authorize(Vocabulary)
    if params.dig(:vocabulary, :institution_id).blank?
      render plain: "Missing institution ID", status: :bad_request
      return
    end
    @vocabulary = Vocabulary.new(vocabulary_params)
    render partial: "form", locals: { vocabulary: @vocabulary }
  end

  ##
  # Responds to `GET /vocabularies/:id`
  #
  def show
    @permitted_params = params.permit(Search::RESULTS_PARAMS +
                                        Search::SIMPLE_SEARCH_PARAMS)
    @start            = [@permitted_params[:start].to_i.abs, MAX_START].min
    @window           = window_size
    q                 = "%#{@permitted_params[:q]&.downcase}%"
    @terms            = @vocabulary.vocabulary_terms.
      where("LOWER(displayed_value) LIKE ? OR LOWER(stored_value) LIKE ?", q, q).
      order(:displayed_value)
    @count            = @terms.count
    @terms            = @terms.limit(@window).offset(@start)
    @current_page     = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
  end

  ##
  # Responds to `PATCH/PUT /vocabularies/:id`
  #
  def update
    begin
      @vocabulary.update!(vocabulary_params)
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @vocabulary.errors.any? ? @vocabulary : e },
             status: :bad_request
    else
      toast!(title:   "Vocabulary updated",
             message: "The vocabulary \"#{@vocabulary.name}\" has been updated.")
      render "shared/reload"
    end
  end


  private

  def set_vocabulary
    @vocabulary = Vocabulary.find(params[:id] || params[:vocabulary_id])
    @breadcrumbable = @vocabulary
  end

  def authorize_vocabulary
    @vocabulary ? authorize(@vocabulary) : skip_authorization
  end

  def vocabulary_params
    params.require(:vocabulary).permit(:institution_id, :name)
  end

end
