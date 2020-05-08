# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit

  protect_from_forgery with: :null_session
  helper_method :current_user, :logged_in?, :to_do_list

  rescue_from StandardError, with: :error_occurred
  rescue_from ActionView::MissingTemplate do |_exception|
    render json: {}, status: :unprocessable_entity
  end
  rescue_from Pundit::NotAuthorizedError, with: :unauthorized

  before_action :store_location
  after_action :copy_flash_to_response_headers

  ##
  # @return [User] The logged-in user, or `nil` if there is none.
  #
  def current_user
    unless @current_user
      if session[:user_id]
        begin
          @current_user = User.find(session[:user_id])
        rescue ActiveRecord::RecordNotFound
          session[:user_id] = nil
        end
      end
    end
    @current_user
  end

  def logged_in?
    current_user.present?
  end

  def store_location
    if request.get? && !request.xhr?
      ignored_paths = ["/auth/failure", "/auth/shibboleth/callback", login_path,
                       logout_path, netid_login_path]
      if !ignored_paths.include?(request.path)
        session[:previous_url]     = request.fullpath
        session[:login_return_url] = request.env["REQUEST_URI"]
      end
    end
  end

  def redirect_path
    session[:previous_url] || main_app.root_url
  end

  protected

  def ensure_logged_in
    redirect_to login_path unless logged_in?
  end

  def ensure_logged_out
    redirect_to root_path if logged_in?
  end

  def error_occurred(exception)
    if exception.class == ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { render "errors/error404", status: :not_found }
        format.json { render nothing: true, status: :not_found }
        format.all { render "errors/error404", status: :not_found }
      end

    else
      exception_string = "Error on #{::Configuration.instance.website[:base_url]}"
      exception_string += "\nclass: #{exception.class}"
      exception_string += "\nmessage: #{exception.message}\n"
      exception_string += Time.now.utc.iso8601
      exception_string += "\nstack:\n"
      exception.backtrace.each do |line|
        exception_string += line
        exception_string += "\n"
      end

      Rails.logger.warn(exception_string)

      unless Rails.env.development?
        exception_string += "\nCurrent User: #{current_user.name} | #{current_user.email}" if current_user
        notification = IdealsMailer.error(exception_string)
        notification.deliver_now
      end
      respond_to do |format|
        format.html { render "errors/error500", status: :internal_server_error }
        format.json { render nothing: true, status: :internal_server_error }
        format.xml { render xml: {status: 500}.to_xml }
      end
    end
  end

  ##
  # Overrides the "user" object supplied to Pundit policy methods. See
  # {UserContext} for more information.
  #
  def pundit_user
    # Read the role from the URL query and write it to the session so that it
    # will persist across pages without having to add it into links.
    # If a role was not provided in the query, read it from the session.
    role_limit = params[:role]
    if role_limit.present?
      role_limit           = role_limit.to_i
      session[:role_limit] = role_limit
    else
      role_limit           = session[:role_limit]
      role_limit         ||= Role::NO_LIMIT
      session[:role_limit] = role_limit
    end
    UserContext.new(current_user, role_limit)
  end

  def unauthorized
    respond_to do |format|
      format.html { render "errors/error403", status: :forbidden }
      format.json { render nothing: true, status: :forbidden }
      format.xml { render xml: {status: 403}.to_xml }
    end
  end

  def results_params
    params.permit(:q, :sort, :start, :window, fq: [])
  end

  ##
  # @return [ToDoList] The {ApplicationController#current_user current user}'s
  #                    to-do list. The result is cached.
  #
  def to_do_list
    if @list.nil?
      @list = ToDoList.new
      # Pending Invitees (if the user is allowed to act on them)
      if policy(Invitee).approve?
        count = Invitee.where(approval_state: ApprovalState::PENDING).count
        if count > 0
          @list.items << {
              message: "Act on #{count} #{"invitee".pluralize(count)}",
              url: invitees_path(approval_state: ApprovalState::PENDING)
          }
          @list.total_items += count
        end
      end

      # Submissions
      count = current_user.submitted_items.where(submitting: true).count
      if count > 0
        @list.items << {
            message: "Resume #{count} #{"submission".pluralize(count)}",
            url: deposit_path
        }
        @list.total_items += count
      end
    end
    @list
  end

  ##
  # @return [Integer] Effective window size a.k.a. results limit based on the
  #                   application configuration and `window` query argument.
  #
  def window_size
    config  = ::Configuration.instance
    default = config.website[:window][:default]
    min     = config.website[:window][:min]
    max     = config.website[:window][:max]
    client  = params[:window].to_i
    if client < min || client > max
      return default
    end
    client
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

end
