# frozen_string_literal: true

class WelcomeController < ApplicationController
  def index; end

  def items; end

  def help; end

  def policies; end

  def dashboard
    @pending_identity_request_count = Invitee.where(approval_state: Ideals::ApprovalState::PENDING).count.to_s
  end

  def deposit; end

  def login_choice
    session[:login_return_referer] = request.env["HTTP_REFERER"]
  end

  def on_failed_registration; end
end
