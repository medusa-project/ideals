# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :ensure_logged_in
  before_action -> { authorize(:dashboard) }
  before_action :set_user

  ##
  # Responds to `GET /dashboard`
  #
  def index
    # Pending Invitees tab
    start            = results_params[:start].to_i
    @invitees_window = window_size
    @invitees        = Invitee.
        where(approval_state: ApprovalState::PENDING).
        limit(@invitees_window).
        offset(start)
    @invitees_count            = @invitees.count
    @invitees_current_page     = ((start / @invitees_window.to_f).ceil + 1 if @invitees_window > 0) || 1
    @invitees_permitted_params = params.permit

    # Submissions tab
    @submissions_in_progress = @user.submitted_items.
        where(submitting: true).
        order(updated_at: :desc) if @user
  end

  private

  def set_user
    @user = current_user
  end

end
