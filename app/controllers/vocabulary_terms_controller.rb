class VocabularyTermsController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_vocabulary, only: [:create, :new]
  before_action :set_term, only: [:edit, :update, :destroy]
  before_action :authorize_term, only: [:edit, :update, :destroy]

  ##
  # Responds to `POST /vocabularies/:vocabulary_id/terms` XHR only)
  #
  def create
    @term = @vocabulary.vocabulary_terms.build(term_params)
    authorize @term, policy_class: VocabularyPolicy
    begin
      @term.save!
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @term.errors.any? ? @term : e },
             status: :bad_request
    else
      flash['success'] = "Term \"#{@term.displayed_value}\" created."
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /vocabularies/:vocabulary_id/terms/:id`
  #
  def destroy
    begin
      @term.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      flash['success'] = "Term \"#{@term.displayed_value}\" deleted."
    ensure
      redirect_back fallback_location: @term.vocabulary
    end
  end

  ##
  # Responds to `GET /vocabularies/:vocabulary_id/terms/:id` (XHR only)
  #
  def edit
    render partial: "vocabulary_terms/form",
           locals: { vocabulary: @term.vocabulary,
                     term:       @term }
  end

  ##
  # Responds to `GET /vocabularies/:vocabulary_id/terms/new` (XHR only)
  #
  def new
    @term = VocabularyTerm.new
    authorize @term, policy_class: VocabularyPolicy
    render partial: "form", locals: { vocabulary: @vocabulary,
                                      term:       @term }
  end

  ##
  # Responds to `PATCH /vocabularies/:vocabulary_id/terms/:id` (XHR only)
  #
  def update
    begin
      @term.update!(term_params)
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @term.errors.any? ? @term : e },
             status: :bad_request
    else
      flash['success'] = "Term \"#{@term.displayed_value}\" updated."
      render "shared/reload"
    end
  end


  private

  def term_params
    params.require(:vocabulary_term).permit(:displayed_value, :stored_value)
  end

  def set_term
    @term = VocabularyTerm.find(params[:id])
  end

  def set_vocabulary
    @vocabulary = Vocabulary.find(params[:vocabulary_id])
  end

  def authorize_term
    @term ? authorize(@term) : skip_authorization
  end

end
