# frozen_string_literal: true

class ApplicationController < ActionController::Base

  protect_from_forgery with: :exception
  helper_method :current_user, :logged_in?, :to_do_list

  rescue_from StandardError, with: :rescue_server_error
  rescue_from ActionController::InvalidAuthenticityToken, with: :rescue_invalid_auth_token
  rescue_from ActionController::InvalidCrossOriginRequest, with: :rescue_invalid_cross_origin_request
  rescue_from ActionController::UnknownFormat, with: :rescue_unknown_format
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :rescue_parse_error
  rescue_from ActionDispatch::RemoteIp::IpSpoofAttackError, with: :rescue_ip_spoof
  rescue_from ActiveRecord::RecordNotFound, with: :rescue_not_found
  rescue_from GoneError, with: :rescue_gone
  rescue_from NotAuthorizedError, with: :rescue_unauthorized

  before_action :redirect_to_main_host, :log_out_disabled_user
  after_action :copy_flash_to_response_headers

  ##
  # @param entity [Class] Model or any other object to which access can be
  #               authorized.
  # @param policy_class [ApplicationPolicy] Alternative policy class to use.
  # @param policy_method [Symbol] Alternative policy method to use.
  # @raises [NotAuthorizedError]
  #
  def authorize(entity, policy_class: nil, policy_method: nil)
    policy_class ||= "#{controller_name.singularize.camelize}Policy".constantize
    instance = policy_class.new(request_context, entity)
    result   = instance.send(policy_method&.to_sym || action_name.to_sym)
    unless result[:authorized]
      e = NotAuthorizedError.new
      e.reason = result[:reason]
      raise e
    end
  end

  ##
  # Returns the institution whose FQDN corresponds to the `X-Forwarded-Host`
  # request header. Note that in global scope, there will not be such an
  # institution, in which case the {Institution#default default institution}
  # will be returned, which won't be what is wanted. Therefore this method
  # should only be used after the scope is known--either from a controller
  # action with a known scope, or after using {institution_scope?}.
  #
  # @return [Institution]
  # @see institution_scope?
  #
  def current_institution
    helpers.current_institution
  end

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

  ##
  # @return [Boolean]
  # @see current_institution
  #
  def institution_scope?
    helpers.institution_scope?
  end

  def logged_in?
    current_user.present?
  end

  ##
  # @return [ApplicationPolicy] Concrete subclass.
  #
  def policy(entity)
    class_ = entity.is_a?(Class) ? entity : entity.class
    "#{class_}Policy".constantize.new(request_context, entity)
  end

  def policy_scope(relation, **options)
    class_ = options[:policy_scope_class] ||
        "#{controller_name.singularize.camelize}Policy::Scope".constantize
    instance = class_.new(request_context, relation, **options)
    instance.resolve
  end

  ##
  # @return [RequestContext]
  #
  def request_context
    # Read the role from the URL query and write it to the session so that it
    # will persist across pages without having to add it into link URLs.
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
    RequestContext.new(client_ip:       request.remote_ip,
                       client_hostname: request.hostname,
                       user:            current_user,
                       institution:     current_institution,
                       role_limit:      role_limit)
  end

  ##
  # Vestigial growth from when we were using the Pundit gem.
  #
  def skip_authorization
  end

  def store_location
    session[:previous_url]     = request.fullpath
    session[:login_return_url] = request.env["REQUEST_URI"]
  end

  def redirect_path
    session[:previous_url] || root_url
  end


  protected

  def ensure_logged_in
    unless logged_in?
      if request.xhr?
        render plain: "403 Forbidden", status: :forbidden
      else
        ins  = current_institution
        host = ins ? ins.fqdn : ::Configuration.instance.main_host
        flash['error'] = "Please log in."
        redirect_to "https://#{host}", allow_other_host: true
      end
    end
  end

  def ensure_logged_out
    redirect_to root_path if logged_in?
  end

  def rescue_gone(e)
    respond_to do |format|
      format.html { render "errors/error410", status: :gone }
      format.json { head status: :gone }
      format.xml { render xml: {status: 410}.to_xml, status: :gone }
    end
  end

  def rescue_ip_spoof
    render plain: 'Client IP mismatch.', status: :bad_request
  end

  ##
  # By default, Rails logs [ActionController::InvalidAuthenticityToken]s at
  # error level. This only bloats the logs, so we handle it differently.
  #
  def rescue_invalid_auth_token
    render plain: "Invalid authenticity token.", status: :bad_request
  end

  ##
  # By default, Rails logs [ActionController::InvalidCrossOriginRequest]s at
  # error level. This only bloats the logs, so we handle it differently.
  #
  def rescue_invalid_cross_origin_request
    render plain: "Invalid cross-origin request.", status: :bad_request
  end

  def rescue_not_found
    message = "This resource does not exist."
    respond_to do |format|
      format.html do
        render "errors/error404", status: :not_found, locals: {
          status_code: 404,
          status_message: "Not Found",
          message: message
        }
      end
      format.json do
        render "errors/error404", status: :not_found, locals: { message: message }
      end
      format.all do
        render plain: "404 Not Found", status: :not_found,
               content_type: "text/plain"
      end
    end
  end

  def rescue_parse_error
    render plain: 'Invalid request parameters.', status: :bad_request
  end

  def rescue_server_error(exception)
    if exception.class == ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { render "errors/error404", status: :not_found }
        format.json { head status: :not_found }
        format.all { render "errors/error404", status: :not_found }
      end

    else
      @message = IdealsMailer.error_body(exception,
                                         url_path: request.path,
                                         user:     current_user)
      Rails.logger.error(@message)
      IdealsMailer.error(@message).deliver_now unless Rails.env.development?

      respond_to do |format|
        format.html do
          render "errors/error500",
                 status: :internal_server_error,
                 content_type: "text/html"
        end
        format.all do
          render plain: "HTTP 500 Internal Server Error",
                 status: :internal_server_error,
                 content_type: "text/plain"
        end
      end
    end
  end

  def rescue_unauthorized(e)
    @reason = e.reason || e.message
    respond_to do |format|
      format.html { render "errors/error403", status: :forbidden }
      format.json { render json: @reason, status: :forbidden }
      format.xml { render xml: {status: 403}.to_xml, status: :forbidden }
      format.all { render plain: @reason, status: :forbidden }
    end
  end

  def rescue_unknown_format
    render plain: "Sorry, we aren't able to provide the requested format.",
           status: :unsupported_media_type
  end

  ##
  # @return [ToDoList] The {ApplicationController#current_user current user}'s
  #                    to-do list. The result is cached.
  #
  def to_do_list
    if @list.nil?
      @list = ToDoList.new
      if current_user&.sysadmin?
        count = Institution.where("outgoing_message_queue IS NULL OR outgoing_message_queue = ''").count
        if count > 0
          @list.items << {
            message: "Set up preservation for #{count} #{"institution".pluralize(count)}",
            url:     institutions_path
          }
          @list.total_items += count
        end
      end

      # Pending Invitees (if the user is allowed to act on them)
      if policy(Invitee).approve?
        count = Invitee.where(institution:    current_institution,
                              approval_state: ApprovalState::PENDING).count
        if count > 0
          @list.items << {
              message: "Act on #{count} #{"invitee".pluralize(count)}",
              url:     invitees_path(approval_state: ApprovalState::PENDING)
          }
          @list.total_items += count
        end
      end

      # Items pending review
      if policy(Item).review?
        count = Item.
          joins(collections: :units).
          where("units.institution_id": current_institution.id,
                stage:                  Item::Stages::SUBMITTED).
          count
        if count > 0
          @list.items << {
              message: "Review #{count} #{"item".pluralize(count)}",
              url:     items_review_path
          }
          @list.total_items += count
        end
      end

      # Submissions to complete (outside of the submission view)
      if controller_name != "submissions" || action_name != "edit"
        items = current_user.submitted_items.where(stage: Item::Stages::SUBMITTING)
        count = items.count
        if count > 0
          path = (count == 1) ? edit_submission_path(items.first) : submit_path
          @list.items << {
              message: "Resume #{count} #{"submission".pluralize(count)}",
              url:     path
          }
          @list.total_items += count
        end
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

  ##
  # When a user account is disabled, the user is prevented from logging in (via
  # {SessionsController}). But if they are already logged in, we don't want to
  # let them keep roaming around. Hence this before_action which verifies their
  # account per-request.
  #
  def log_out_disabled_user
    user = current_user
    if user && !user.enabled
      reset_session
      flash['error'] = "Your account has been disabled."
      redirect_to root_path
    end
  end

  ##
  # Redirects to the main host if there is no institution FQDN matching the
  # request host
  #
  def redirect_to_main_host
    # In production, IDEALS has two domains: ideals.illinois.edu and
    # www.ideals.illinois.edu. The latter is the correct one that the former
    # should redirect to, but our Institution model only supports one FQDN, so
    # we have to handle this situation manually here.
    if request.host == "ideals.illinois.edu"
      redirect_to "https://www.#{request.host}",
                  status: :moved_permanently,
                  allow_other_host: true
      return
    end
    main_host = ::Configuration.instance.main_host
    if request.host != main_host && !Institution.exists?(fqdn: request.host_with_port)
      scheme = (Rails.env.development? || Rails.env.test?) ? "http" : "https"
      redirect_to scheme + "://" + main_host,
                  status: :see_other,
                  allow_other_host: true
    end
  end

end
