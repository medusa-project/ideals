class VocabulariesController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_vocabulary, except: [:create, :index, :new]
  before_action :authorize_vocabulary, except: [:create, :index]
  before_action :store_location, only: [:index, :show]

  ##
  # Responds to `POST /vocabularies`
  #
  def create
    @vocabulary             = Vocabulary.new(vocabulary_params)
    @vocabulary.institution = current_institution
    authorize @vocabulary
    begin
      @vocabulary.save!
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @vocabulary.errors.any? ? @vocabulary : e },
             status: :bad_request
    else
      flash['success'] = "Vocabulary \"#{@vocabulary.name}\" created."
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /vocabularies/:id`
  #
  def destroy
    begin
      @vocabulary.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      flash['success'] = "Vocabulary \"#{@vocabulary.name}\" deleted."
    ensure
      redirect_to vocabularies_path
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
    @start            = @permitted_params[:start].to_i
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
  def new
    @vocabulary = Vocabulary.new
    authorize(@vocabulary)
    render partial: "form", locals: { vocabulary: @vocabulary }
  end

  ##
  # Responds to `GET /vocabularies/:id`
  #
  def show
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
      flash['success'] = "Vocabulary \"#{@vocabulary.name}\" has been updated."
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
    params.require(:vocabulary).permit(:key, :name)
  end

end
