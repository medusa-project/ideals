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
      redirect_to "/Shibboleth.sso/Login?target=https://#{shib_opts['host']}/auth/shibboleth/callback"
    end
  end

  ##
  # Handles callbacks from the auth provider (OmniAuth). Responsible for
  # translating an authentication hash into a {User}, assigning the user to
  # an {Institution}, and setting the user's ID in the session.
  #
  # Only {User#enabled enabled users} whose {User#institution owning
  # institution} matches the request institution are allowed to log in. (The
  # only exception is sysadmins who are using the local-identity provider.
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
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth, institution: current_institution)

    # Is the user allowed to log in?
    if user&.enabled && (user.institution == current_institution || user.sysadmin?)
      # Yes!
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
    redirect_to institution_host? ? current_institution.scope_url : root_url,
                allow_other_host: true
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

  def unauthorized
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

end
