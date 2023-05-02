# frozen_string_literal: true

class SessionsController < ApplicationController

  skip_before_action :verify_authenticity_token, except: :new_netid

  ##
  # Redirects to the Shibboleth login flow. Responds to
  # `GET/POST /netid-login`.
  #
  def new_netid
    if Rails.env.development? || Rails.env.test?
      redirect_to "/auth/developer"
    else
      shib_opts = YAML.load_file(File.join(Rails.root, 'config', 'shibboleth.yml'))[Rails.env]
      redirect_to shibboleth_login_path(shib_opts['host'])
    end
  end

  ##
  # Handles callbacks from the auth provider. (In development this is the
  # OmniAuth development strategy, and in demo/production it's the Shibboleth
  # SP.) It is responsible for taking the UID from the authentication hash,
  # translating it into a {User}, and setting the user's ID in the session.
  #
  # This method will only have been called upon successful authentication--
  # never upon failure. However, only {User#enabled enabled users} whose
  # {User#institution owning institution} matches the request institution are
  # allowed to log in. {LocalUser}s also must have an associated
  # {LocalIdentity}.
  #
  # Responds to `GET/POST /auth/:provider/callback`.
  #
  def create
    auth = request.env["omniauth.auth"]
    user = nil

    case auth[:provider]
    when "developer", "shibboleth"
      user = ShibbolethUser.from_omniauth(auth)
    when "saml"
      user = SamlUser.from_omniauth(auth)
    when "identity"
      user = LocalUser.from_omniauth(auth)
    end

    # Sysadmins can log in via any institution's host. This is a feature needed
    # by CARLI sysadmins for e.g. walking users through how to do things. But
    # there is no use case for non-sysadmins to be able to do this.
    if user&.id && user.enabled && (user.institution == current_institution || user.sysadmin?)
      begin
        hostname = Resolv.getname(request.remote_ip)
      rescue Resolv::ResolvError
        hostname = nil
      end
      user.logins.build(ip_address: request.remote_ip,
                        hostname:   hostname,
                        auth_hash:  auth).save!
      return_url_ = return_url
      # Protect against session fixation:
      # https://guides.rubyonrails.org/security.html#session-fixation-countermeasures
      reset_session
      session[:user_id] = user.id
      redirect_to return_url_
    else
      unauthorized
    end
  end

  def destroy
    reset_session
    redirect_to(institution_host? ? current_institution.scope_url : root_url,
                allow_other_host: true)
  end

  ##
  # Handles omniauth-identity authentication failures.
  #
  # Responds to `GET /auth/failure`.
  #
  def auth_failed
    message = "Login failed: incorrect username and/or password."
    if request.xhr?
      render plain: message, status: :unauthorized
    else
      flash['error'] = message
      redirect_to return_url, allow_other_host: true
    end
  end

  def unauthorized # TODO: this should be private
    message = "You are not authorized to log in. "\
              "If this problem persists, please contact us."
    if request.xhr?
      render plain: message, status: :forbidden
    else
      flash['error'] = message
      redirect_to return_url, allow_other_host: true
    end
  end


  private

  def return_url
    session[:login_return_url] || current_institution&.scope_url || root_url
  end

  def shibboleth_login_path(host)
    "/Shibboleth.sso/Login?target=https://#{host}/auth/shibboleth/callback"
  end

end
