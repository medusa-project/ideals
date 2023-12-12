# frozen_string_literal: true

class VocabularyTermsController < ApplicationController

  before_action :ensure_institution_host, :ensure_logged_in
  before_action :set_vocabulary, only: [:create, :import, :new]
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
      toast!(title:   "Term created",
             message: "The vocabulary term \"#{@term.displayed_value}\" has "\
                      "been created.")
      render "shared/reload"
    end
  end

  ##
  # Responds to `DELETE /vocabularies/:vocabulary_id/terms/:id`
  #
  def destroy
    @term.destroy!
  rescue => e
    flash['error'] = "#{e}"
  else
    toast!(title:   "Term deleted",
           message: "The vocabulary term \"#{@term.displayed_value}\" has "\
                    "been deleted.")
  ensure
    redirect_back fallback_location: @term.vocabulary
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
  # Responds to `GET/POST /vocabularies/:vocabulary_id/terms/import`
  #
  def import
    authorize(@vocabulary)
    if request.method == "POST"
      tempfile = Tempfile.new("vocabulary_#{@vocabulary.id}_import.csv")
      begin
        # The finalizer would otherwise delete it as it gets GCed.
        ObjectSpace.undefine_finalizer(tempfile)
        csv = params[:csv].read.force_encoding("UTF-8")
        tempfile.write(csv)
        tempfile.close
        task = Task.create!(name: ImportVocabularyTermsJob.to_s)
        ImportVocabularyTermsJob.perform_later(vocabulary: @vocabulary,
                                               pathname:   tempfile.path,
                                               user:       current_user,
                                               task:       task)
      rescue => e
        tempfile.close
        tempfile.unlink
        render partial: "shared/validation_messages",
               locals: { object: e },
               status: :bad_request
      else
        toast!(title:   "Importing file",
               message: "Vocabulary terms are importing in the background, "\
                        "and should be available in a moment.")
        render "shared/reload"
      end
    else
      render partial: "vocabulary_terms/import_form",
             locals: { vocabulary: @vocabulary }
    end
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
    @term.update!(term_params)
  rescue => e
    render partial: "shared/validation_messages",
           locals: { object: @term.errors.any? ? @term : e },
           status: :bad_request
  else
    toast!(title:   "Term updated",
           message: "The vocabulary term \"#{@term.displayed_value}\" has "\
                    "been updated.")
    render "shared/reload"
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
