# frozen_string_literal: true

class MessagesController < ApplicationController

  before_action :ensure_logged_in
  before_action :authorize_index, only: :index
  before_action :load_message, only: :show
  before_action :authorize_message, only: :show
  before_action :store_location, only: [:index, :show]

  ##
  # Responds to `GET /messages`.
  #
  def index
    @messages = Message.order(updated_at: :desc).limit(100)
  end

  def show
    @breadcrumbable = @message
  end


  private

  def authorize_index
    authorize(Message)
  end

  def load_message
    @message = Message.find(params[:id])
  end

  def authorize_message
    @message ? authorize(@message) : skip_authorization
  end

end
