# frozen_string_literal: true

class MessagesController < ApplicationController

  before_action :ensure_logged_in, :authorize_sysadmin

  ##
  # Responds to `GET /messages`.
  #
  def index
    @messages = Message.order(updated_at: :desc).limit(100)
  end


  private

  def authorize_sysadmin
    authorize(Message)
  end

end
