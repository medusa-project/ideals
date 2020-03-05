# frozen_string_literal: true

class SubmissionsController < ApplicationController

  before_action :ensure_logged_in
  before_action :set_submission, only: [:destroy, :edit, :update]
  before_action :authorize_submission, only: [:edit, :update, :destroy]

  ##
  # Creates a new {Submission} upon acceptance of the {deposit deposit
  # agreement}. After the submission has been created, the user is redirected
  # to {edit}.
  #
  # Responds to `POST /submissions`.
  #
  def create
    submission = Submission.create!(user: current_user,
                                    collection_id: params[:collection_id])
    authorize submission # this should always succeed
    redirect_to edit_submission_path(submission)
  end

  ##
  # Displays the deposit agreement. At the end of the agreement is a submit
  # button that POSTs to {create}.
  #
  # Responds to `GET /deposit`.
  #
  def deposit
    authorize Submission
    @submissions = current_user.submissions.order(:updated_at)
  end

  ##
  # Responds to `DELETE /submissions/:id`
  #
  def destroy
    begin
      @submission.destroy!
    rescue => e
      flash['error'] = "#{e}"
    else
      flash['success'] = "Submission deleted."
    ensure
      redirect_back fallback_location: root_path
    end
  end

  ##
  # Responds to `GET /submissions/:id/edit`.
  #
  def edit
  end

  ##
  # Responds to `POST/PATCH /submissions/:id`.
  #
  def update
    # TODO: write this
  end


  private

  def authorize_submission
    @submission ? authorize(@submission) : skip_authorization
  end

  def set_submission
    @submission = Submission.find(params[:id] || params[:submission_id])
  end

end
