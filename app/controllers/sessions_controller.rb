# frozen_string_literal: true

class SessionsController < ApplicationController

  skip_before_action :verify_authenticity_token, only: :create

  ##
  # Displays the login page. Responds to `GET /login`.
  #
  def new
  end

  ##
  # Redirects to the Shibboleth login flow. Responds to
  # `GET/POST /netid-login`.
  #
  def new_netid
    if Rails.env.development? || Rails.env.test?
      redirect_to "/auth/developer"
    else
      redirect_to shibboleth_login_path(Ideals::Application.shibboleth_host)
    end
  end

  ##
  # Responds to `GET/POST /auth/:provider/callback`.
  #
  def create
    auth = request.env["omniauth.auth"]
    user = nil

    case auth[:provider]
    when "developer", "shibboleth"
      user = ShibbolethUser.from_omniauth(auth)
    when "identity"
      user = LocalUser.from_omniauth(auth)
    end

    # We want users to be able to log in only to their current institution's
    # site, except in test, where all requests through the test framework are
    # to www.example.com.
    if user&.id && (Rails.env.test? || user.institution == current_institution)
      user.update!(auth_hash:         auth,
                   last_logged_in_at: Time.now)
      session[:user_id] = user.id
      redirect_to return_url
    else
      unauthorized
    end
  end

  def destroy
    reset_session
    redirect_back fallback_location: root_url
  end

  def unauthorized
    render plain: "401 Unauthorized", status: :unauthorized
  end

  protected

  def return_url
    session[:login_return_url] || root_url
  end

  def shibboleth_login_path(host)
    "/Shibboleth.sso/Login?target=https://#{host}/auth/shibboleth/callback"
  end
end
