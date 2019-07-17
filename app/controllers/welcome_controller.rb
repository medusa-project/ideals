# frozen_string_literal: true

class WelcomeController < ApplicationController
  def index; end

  def items; end

  def help; end

  def policies; end

  def dashboard
    @pending_identity_request_count = Invitee.where(approved: nil).count.to_s
  end

  def deposit; end

  def login_choice; end

  def on_failed_registration
  end

end
