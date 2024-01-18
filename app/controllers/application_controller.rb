# frozen_string_literal: true

##
# Controller from which all other controllers inherit.
#
class ApplicationController < ActionController::Base

  protect_from_forgery with: :exception
  helper_method :current_user, :current_user_is_sysadmin?, :logged_in?,
                :request_context, :to_do_list

  rescue_from StandardError, with: :rescue_server_error
  rescue_from ActionController::InvalidAuthenticityToken, with: :rescue_invalid_auth_token
  rescue_from ActionController::InvalidCrossOriginRequest, with: :rescue_invalid_cross_origin_request
  rescue_from ActionController::UnknownFormat, with: :rescue_unknown_format
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :rescue_parse_error
  rescue_from ActiveRecord::RecordNotFound, with: :rescue_not_found
  rescue_from GoneError, with: :rescue_gone
  rescue_from NotAuthorizedError, with: :rescue_unauthorized
  rescue_from NotFoundError, with: :rescue_not_found

  before_action :redirect_to_main_host, :log_out_disabled_user

  layout -> { institution_host? ? "application_scoped" : "application_global" }

  ##
  # Authorizes user access to some object. The object must have a corresponding
  # policy class, which lives in the app/policies folder and has a class name
  # matching that of the object but with `Policy` appended to it.
  #
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
  # Checks whether the client has passed a CAPTCHA test. Three form fields are
  # checked:
  #
  # 1. A hash of the salted correct answer to a question, e.g. "what's 5 + 3?"
  # 2. The answer to the question above, provided by the client, whose salted
  #    hash is expected to match #1
  # 3. Another irrelevant field that is hidden via CSS and expected to remain
  #    unfilled (the "honeypot technique")
  #
  # This method works in conjunction with {ApplicationHelper#captcha}.
  #
  # @return [Boolean] If `false`, the check failed and the caller should
  #                   prepare an appropriate error response.
  #
  def check_captcha
    # Check the honeypot
    email   = params[:honey_email]
    success = email.blank?
    if success
      # Check the answer
      answer_hash   = Digest::MD5.hexdigest("#{params[:answer]}#{ApplicationHelper::CAPTCHA_SALT}")
      expected_hash = params[:correct_answer_hash]
      success       = (answer_hash == expected_hash)
    end
    success
  end

  ##
  # Returns the institution whose FQDN corresponds to the `X-Forwarded-Host`
  # request header.
  #
  # N.B.: in global scope, there will not be such an institution, in which case
  # the {Institution#default default institution} will be returned, which won't
  # be what is wanted. Therefore this method should only be used after the
  # scope is known--either from a controller action with a known scope, or
  # after {institution_host?} returns `true`.
  #
  # @return [Institution]
  # @see institution_host?
  #
  def current_institution
    helpers.current_institution
  end

  ##
  # @return [User] The logged-in user, or `nil` if there isn't one.
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
  # Shortcut to invoking {User#sysadmin?} on the return value of
  # {#current_user}.
  #
  # @return [Boolean]
  #
  def current_user_is_sysadmin?
    current_user&.sysadmin?(client_ip:       request_context.client_ip,
                            client_hostname: request_context.client_hostname)
  end

  ##
  # @return [Boolean]
  # @see current_institution
  #
  def institution_host?
    helpers.institution_host?
  end

  ##
  # @return [Boolean] Equivalent to checking whether {#current_user} returns a
  #                   {User}.
  #
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
    unless @request_context
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
      begin
        hostname = Resolv.getname(request.remote_ip)
      rescue Resolv::ResolvError
        hostname = nil
      end
      @request_context = RequestContext.new(client_ip:       request.remote_ip,
                                            client_hostname: hostname,
                                            user:            current_user,
                                            institution:     current_institution,
                                            role_limit:      role_limit)
    end
    @request_context
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


  protected

  def ensure_institution_host
    raise NotFoundError unless institution_host?
  end

  def ensure_logged_in
    unless logged_in?
      if request.xhr?
        render plain: "403 Forbidden", status: :forbidden
      else
        ins  = current_institution
        host = ins ? ins.fqdn : ::Configuration.instance.main_host
        flash['error'] = "Please log in."
        scheme = (Rails.env.development? || Rails.env.test?) ? "http" : "https"
        redirect_to "#{scheme}://#{host}", allow_other_host: true
      end
    end
  end

  def ensure_logged_out
    redirect_to root_path if logged_in?
  end

  ##
  # @return Maximum OpenSearch-safe start/offset within a results list.
  # @see window_size
  #
  def max_start
    OpenSearchIndex::MAX_RESULT_WINDOW - window_size
  end

  def rescue_gone
    respond_to do |format|
      format.html { render "errors/error410", status: :gone }
      format.json { head status: :gone }
      format.xml { render xml: {status: 410}.to_xml, status: :gone }
    end
  end

  ##
  # By default, Rails logs {ActionController::InvalidAuthenticityToken}s at
  # error level. This provides no benefit and bloats our logs, so we handle it
  # differently.
  #
  def rescue_invalid_auth_token
    render plain: "Invalid authenticity token.", status: :bad_request
  end

  ##
  # By default, Rails logs {ActionController::InvalidCrossOriginRequest}s at
  # error level. This provides no benefit and bloats our logs, so we handle it
  # differently.
  #
  def rescue_invalid_cross_origin_request
    # do nothing to avoid a DoubleRenderError
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
    @breadcrumbable = nil # we don't want a breadcrumb on our error page
    @message        = IdealsMailer.error_body(exception,
                                              method:   request.method,
                                              host:     request.host,
                                              url_path: request.path,
                                              query:    request.query_string,
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

  def rescue_unauthorized(e)
    @breadcrumbable = nil # we don't want a breadcrumb on our error page
    @reason         = e.reason || e.message
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
      # Preservation alerts
      if current_user_is_sysadmin?
        count = Institution.where("outgoing_message_queue IS NULL OR outgoing_message_queue = ''").count
        if count > 0
          @list.items << {
            message: "Set up preservation for #{count} #{"institution".pluralize(count)}",
            url:     institutions_path
          }
          @list.total_items += count
        end
      end

      # Metadata profiles
      profiles        = current_institution.metadata_profiles
      default_profile = profiles.find(&:institution_default)
      if !default_profile && policy(profiles.first).edit?
        @list.items << {
          message: "Set a default metadata profile",
          url:     metadata_profiles_path
        }
        @list.total_items += 1
      end

      # Submission profiles
      profiles        = current_institution.submission_profiles
      default_profile = profiles.find(&:institution_default)
      if !default_profile && policy(profiles.first).edit?
        @list.items << {
          message: "Set a default submission profile",
          url:     submission_profiles_path
        }
        @list.total_items += 1
      end

      # Pending Invitees (if the user is allowed to act on them)
      if policy(Invitee).approve?
        count = Invitee.where(institution:    current_institution,
                              approval_state: Invitee::ApprovalState::PENDING).count
        if count > 0
          @list.items << {
              message: "Act on #{count} #{"invitee".pluralize(count)}",
              url:     invitees_path(approval_state: Invitee::ApprovalState::PENDING)
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
              url:     review_items_path
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
  # Sets the toast.
  #
  # @param title [String]
  # @param message [String]
  # @param icon [String,Symbol]
  #
  # @see ApplicationHelper#toast!
  #
  def toast!(title: nil, message:, icon: nil)
    helpers.toast!(title: title, message: message, icon: icon)
  end

  ##
  # @return [Integer] Effective window size a.k.a. result limit based on the
  #                   application configuration and `window` query argument.
  # @see max_start
  #
  def window_size
    default_default = 25
    default_min     = 20
    default_max     = 100
    default = Setting.integer(Setting::Key::RESULT_WINDOW_DEFAULT, default_default)
    default = default_default if default < 1
    min     = Setting.integer(Setting::Key::RESULT_WINDOW_MIN, default_min)
    min     = default_min if min < 1
    max     = Setting.integer(Setting::Key::RESULT_WINDOW_MAX, default_max)
    max     = default_max if max < 1
    client  = params[:window].to_i
    if client < min || client > max
      return default
    end
    client
  end


  private

  ##
  # When a user account is disabled, the user is prevented from logging in (via
  # {SessionsController#create}). But if they are already logged in, we don't
  # want to let them keep roaming around. Thus this before_action which
  # verifies their account per-request.
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
    # In production, IDEALS has several domains:
    #
    # * scholarship.illinois.edu (global landing page, still under development,
    #   redirects to www.ideals.illinois.edu until it's ready)
    # * www.ideals.illinois.edu (scoped to UIUC content)
    # * ideals.illinois.edu (redirects permanently to www.ideals.illinois.edu)
    # * <institution>.scholarship.illinois.edu (scoped to a non-UIUC
    #   institution)
    #
    # And in demo:
    #
    # * demo.scholarship.illinois.edu (global landing page)
    # * demo.ideals.illinois.edu (scoped to UIUC content)
    # * <institution>.demo.scholarship.illinois.edu (scoped to a non-UIUC
    #   institution)
    case request.host
    when "scholarship.illinois.edu" # this condition will be removed when the global landing page is ready
      redirect_to "https://www.ideals.illinois.edu#{request.fullpath}",
                  status: 302,
                  allow_other_host: true
      return
    when "ideals.illinois.edu"
      redirect_to "https://www.ideals.illinois.edu#{request.fullpath}",
                  status: :moved_permanently,
                  allow_other_host: true
      return
    else
      main_host = ::Configuration.instance.main_host
      if request.host != main_host && !Institution.exists?(fqdn: request.host_with_port)
        scheme = (Rails.env.development? || Rails.env.test?) ? "http" : "https"
        redirect_to scheme + "://" + main_host,
                    status: :see_other,
                    allow_other_host: true
      end
    end
  end

end
