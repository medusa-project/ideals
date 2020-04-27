# frozen_string_literal: true

class SessionsController < ApplicationController

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
    redirect_to(shibboleth_login_path(Ideals::Application.shibboleth_host))
  end

  def create
    auth = request.env["omniauth.auth"]
    user = nil

    case auth[:provider]
    when "shibboleth"
      user = ShibbolethUser.from_omniauth(auth)
    when "identity"
      user = LocalUser.from_omniauth(auth)
    else
      unauthorized
    end

    if user&.id
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
    session[:login_return_uri] || root_url
  end

  def shibboleth_login_path(host)
    "/Shibboleth.sso/Login?target=https://#{host}/auth/shibboleth/callback"
  end
end
