# frozen_string_literal: true

class WelcomeController < ApplicationController

  helper_method :current_user, :logged_in?

  def index; end

  def items; end

  def help; end

  def policies; end

  def dashboard
    if current_user && current_user.role == Ideals::UserRole::ADMIN
      @pending_identity_request_count = Invitee.where(approval_state: Ideals::ApprovalState::PENDING).count.to_s
    end
  end

  def deposit; end

  def login_choice
    session[:login_return_referer] = request.env["HTTP_REFERER"]
  end

  def on_failed_registration; end
end
