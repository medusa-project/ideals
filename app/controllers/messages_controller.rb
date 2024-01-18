# frozen_string_literal: true

class MessagesController < ApplicationController

  before_action :ensure_institution_host, :ensure_logged_in
  before_action :authorize_index, only: :index
  before_action :load_message, except: :index
  before_action :authorize_message, only: [:resend, :show]
  before_action :store_location, only: [:index, :show]

  ##
  # Responds to `GET /messages`.
  #
  def index
    @permitted_params = results_params
    @start            = [@permitted_params[:start].to_i.abs, max_start].min
    @window           = window_size
    @messages         = Message.all.order(updated_at: :desc)
    if @permitted_params[:key].present?
      @messages = @messages.where("LOWER(staging_key) LIKE ?",
                                  "%#{@permitted_params[:key].downcase}%")
    end
    if @permitted_params[:status].present?
      if @permitted_params[:status] == "no_response"
        @messages = @messages.where(response_time: nil)
      else
        @messages = @messages.where(status: @permitted_params[:status])
      end
    end
    @count            = @messages.count
    @messages         = @messages.limit(@window).offset(@start)
    @current_page     = ((@start / @window.to_f).ceil + 1 if @window > 0) || 1
  end

  ##
  # Responds to `POST /messages/:id/resend`.
  #
  def resend
    @message.resend
  rescue => e
    flash['error'] = "#{e}"
  else
    toast!(title:   "Message resent",
           message: "Message ##{@message.id} has been resent.")
  ensure
    redirect_back fallback_location: messages_path
  end

  def show
  end


  private

  def authorize_index
    authorize(Message)
  end

  def load_message
    @message = Message.find(params[:id] || params[:message_id])
  end

  def authorize_message
    @message ? authorize(@message) : skip_authorization
  end

  def results_params
    params.permit(:key, :start, :status)
  end

end
