# frozen_string_literal: true

class SessionsController < ApplicationController

  LOGGER = CustomLogger.new(SessionsController)

  skip_before_action :verify_authenticity_token, except: :new
  before_action :require_institution_host, only: :new

  ##
  # Provides a "back door" login form. This is not linked to from anywhere
  # else, but it can be used by sysadmins to log into other institutions when
  # they don't have local-credentials logins enabled.
  #
  # Responds to `GET /login`
  #
  def new
    redirect_to root_path if logged_in?
    session[:login_failure_url] = login_url
  end

  ##
  # Handles callbacks from the auth provider (OmniAuth). Responsible for
  # translating an authentication hash into a {User}, assigning the user to
  # an {Institution}, and setting the user's ID in the session.
  #
  # Only {User#enabled enabled users} whose {User#institution owning
  # institution} matches the request institution are allowed to log in. (The
  # only exception is sysadmins who are using the local-credentials provider.
  # This is a feature needed by CARLI sysadmins for e.g. walking users through
  # how to do things. But there is no use case for non-sysadmins to be able to
  # do this, and no way to support it for OpenAthens users, because the IdP
  # response doesn't reliably contain their institution.)
  #
  # This method will only have been called upon successful authentication--
  # never upon failure.
  #
  # Responds to `GET/POST /auth/:provider/callback`.
  #
  def create
    unless %w[saml identity developer].include?(params[:provider])
      render plain: "404 Not Found", status: :not_found
      return
    end
    auth = request.env["omniauth.auth"]
    LOGGER.info("Received OmniAuth login hash: %s", auth)
    user = User.from_omniauth(auth, institution: current_institution)
    if user
      if user.email.blank?
        if params[:provider] == "saml"
          unauthorized(message: "Failed to find an email address in the SAML "\
                                "response. (Are the email location and/or "\
                                "attribute set correctly?)") and return
        else
          unauthorized(message: "No email address provided.") and return
        end
      elsif !user.enabled
        LOGGER.info("User %s tried to log into a disabled account", user.email)
        unauthorized(message: "This user account is disabled.") and return
      elsif user.institution != current_institution &&
        # Sysadmins are able to log into other institutions, but only via the
        # identity provider.
        (params[:provider] == "saml" || !user.sysadmin?(client_ip:       request_context.client_ip,
                                                        client_hostname: request_context.client_hostname))
        LOGGER.info("User %s tried to log into a different institution's domain via %s",
                    user.email, params[:provider])
        unauthorized(message: "You must log in via your home institution's domain.") and return
      end
    else
      unauthorized(message: "Unable to decode the authentication response.") and return
    end

    # At this point, we know we have a valid user who is authorized to log in.
    LOGGER.info("Successful %s login for user %s",
                params[:provider], user.email)
    begin
      hostname = Resolv.getname(request.remote_ip)
    rescue Resolv::ResolvError
      hostname = nil
    end
    user.logins.build(ip_address:  request.remote_ip,
                      hostname:    hostname,
                      institution: current_institution,
                      auth_hash:   auth).save!

    if user.caching_submittable_collections_task_id.blank? &&
      (!user.submittable_collections_cached_at ||
        (user.submittable_collections_cached_at &&
          user.submittable_collections_cached_at < 12.hours.ago))
      task = Task.create!(name:        CacheSubmittableCollectionsJob.to_s,
                          user:        user,
                          institution: user.institution)
      CacheSubmittableCollectionsJob.perform_later(user:            user,
                                                   client_ip:       request_context.client_ip,
                                                   client_hostname: request_context.client_hostname,
                                                   task:            task)
    end

    return_url_ = return_url
    # Protect against session fixation:
    # https://guides.rubyonrails.org/security.html#session-fixation-countermeasures
    reset_session
    session[:user_id] = user.id
    redirect_to return_url_
  end

  def destroy
    reset_session
    redirect_to institution_host? ? current_institution.scope_url : root_url,
                allow_other_host: true
  end

  ##
  # Handles omniauth-identity authentication failures.
  #
  # Responds to `GET /auth/failure`.
  #
  def auth_failed
    message = params.dig("message") || "incorrect username and/or password"
    message = "Login failed: #{message}"
    if request.xhr?
      render plain: message, status: :unauthorized
    else
      flash['error'] = message
      redirect_to return_url, allow_other_host: true
    end
  end


  private

  def require_institution_host
    redirect_to root_path unless institution_host?
  end

  def return_url
    session[:login_failure_url] ||
      session[:login_return_url] ||
      current_institution&.scope_url ||
      root_url
  end

  def unauthorized(message: nil)
    message ||= "You are not authorized to log in. "\
                "If this problem persists, please contact us."
    if request.xhr?
      render plain: message, status: :forbidden
    else
      flash['error'] = message
      redirect_to return_url, allow_other_host: true
    end
  end

end
