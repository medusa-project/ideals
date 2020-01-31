# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  helper_method :current_user, :logged_in?

  rescue_from StandardError, with: :error_occurred
  rescue_from ActionView::MissingTemplate do |_exception|
    render json: {}, status: :unprocessable_entity
  end

  after_action :copy_flash_to_response_headers, :store_location

  def store_location
    return nil unless request.get?

    if request.path != login_path and
        request.path != logout_path and
        !request.xhr? # don't store ajax calls
      session[:previous_url] = request.fullpath
      session[:login_return_uri] = request.env["REQUEST_URI"]
    end
  end

  def redirect_path
    session[:previous_url] || main_app.root_url
  end

  protected

  def authorize_user
    redirect_to login_path unless logged_in?
  end

  def error_occurred(exception)
    if exception.class == ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { render "errors/error404", status: :not_found }
        format.json { render nothing: true, status: :not_found }
        format.all { render "errors/error404", status: :not_found }
      end

    else
      exception_string = "Error on #{::Configuration.instance.root_url_text}"
      exception_string += "\nclass: #{exception.class}"
      exception_string += "\nmessage: #{exception.message}\n"
      exception_string += Time.now.utc.iso8601
      exception_string += "\nstack:\n"
      exception.backtrace.each do |line|
        exception_string += line
        exception_string += "\n"
      end

      Rails.logger.warn(exception_string)

      exception_string += "\nCurrent User: #{current_user.name} | #{current_user.email}" if current_user

      notification = IdealsMailer.error(exception_string)
      notification.deliver_now
      respond_to do |format|
        format.html { render "errors/error500", status: :internal_server_error }
        format.json { render nothing: true, status: :internal_server_error }
        format.xml { render xml: {status: 500}.to_xml }
      end

    end
  end

  def record_not_found(exception)
    Rails.logger.warn exception

    redirect_to redirect_path, alert: "An error occurred and has been logged for review by library staff."
  end

  private

  ##
  # Stores the flash message and type (`error` or `success`) in the response
  # headers, where they can be accessed from a JavaScript AJAX callback.
  #
  def copy_flash_to_response_headers
    if request.xhr?
      if flash['error'].present?
        response.headers['X-Ideals-Message-Type'] = 'error'
        response.headers['X-Ideals-Message']      = flash['error']
      elsif flash['success'].present?
        response.headers['X-Ideals-Message-Type'] = 'success'
        response.headers['X-Ideals-Message']      = flash['success']
      end
    end
  end

  def current_user
    if session[:user_id]
      @current_user = User::Shibboleth.find(session[:user_id]) || User::Identity.find(session[:user_id])
    end
  rescue ActiveRecord::RecordNotFound
    session[:user_id] = nil
  end

  def logged_in?
    current_user.present?
  end

end
