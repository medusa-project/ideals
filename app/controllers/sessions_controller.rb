# frozen_string_literal: true

class SessionsController < ApplicationController
  require_relative "../models/user/shibboleth"

  def new
    redirect_to(shibboleth_login_path(Ideals::Application.shibboleth_host))
  end

  def create
    auth = request.env["omniauth.auth"]

    user = nil

    if auth[:provider] && auth[:provider] == AuthProvider::SHIBBOLETH
      user = User::Shibboleth.from_omniauth(auth)
    elsif auth[:provider] && auth[:provider] == AuthProvider::IDENTITY
      user = User::Identity.from_omniauth(auth)
    else
      unauthorized
    end

    if user&.id
      session[:user_id] = user.id
      render plain: 'Login succeeded.', status: :created
    else
      unauthorized
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url
  end

  def unauthorized
    render plain: 'Login failed.', status: :forbidden
  end

  protected

  def return_url
    session[:login_return_uri] || session[:login_return_referer] || root_url
  end

  def shibboleth_login_path(host)
    "/Shibboleth.sso/Login?target=https://#{host}/auth/shibboleth/callback"
  end
end
