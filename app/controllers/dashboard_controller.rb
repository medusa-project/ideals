# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :ensure_logged_in
  before_action -> { authorize(:dashboard) }
  before_action :set_user

  ##
  # Responds to `GET /dashboard`
  #
  def index
    @submissions_in_progress = @user.submitted_items.
        where(submitting: true).
        order(updated_at: :desc) if @user
  end

  private

  def set_user
    @user = current_user
  end

end
