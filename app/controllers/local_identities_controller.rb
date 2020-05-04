# frozen_string_literal: true

##
# N.B.: see the documentation of {Invitee} for a detailed overview of the
# invitation & registration process.
#
class LocalIdentitiesController < ApplicationController

  before_action :set_identity
  before_action :authorize_identity, only: :register
  before_action :pre_validate_password_reset, only: [:new_password,
                                                     :reset_password]
  before_action :pre_validate_registration, only: :register

  ##
  # Renders the "phase two" reset-password form, containing password and
  # password confirmation fields. (The "phase one" form is handled by
  # {PasswordResetsController}.)
  #
  # Responds to `GET /identities/:id/reset-password`. Requires a `token` query
  # argument.
  #
  def new_password
    @token = params[:token]
  end

  ##
  # Renders the registration form. Requires a `token` query argument which
  # supports incoming links from emails.
  #
  # Responds to `GET /identities/:id/register`.
  #
  def register
  end

  ##
  # Processes the form submitted from {new_password}.
  #
  # Responds to `PATCH/POST /identities/:id/reset-password`.
  #
  def reset_password
    begin
      p = identity_password_params
      @identity.update_password!(password:     p[:password],
                                 confirmation: p[:password_confirmation])
    rescue => e
      flash['error'] = "#{e}"
      new_password
      render "new_password"
    else
      flash['success'] = "Your password has been changed. You may now log in "\
          "using your new password."
      redirect_to root_url
    end
  end

  private

  def authorize_identity
    @identity ? authorize(@identity) : skip_authorization
  end

  def identity_params
    identity_password_params
  end

  def identity_password_params
    params.require(:local_identity).permit(:password, :password_confirmation)
  end

  def pre_validate_password_reset
    token = params[:token].to_s
    # Validate the token.
    unless @identity.authenticated?(:reset, token)
      flash['error'] = "Invalid password reset link."
      redirect_to root_url and return
    end
    # Validate the token expiration.
    if @identity.password_reset_expired?
      flash['error'] = "This password reset link has expired. Please try again."
      redirect_to reset_password_url
    end
  end

  def pre_validate_registration
    # Validate the token.
    unless @identity.authenticated?(:activation, params[:token])
      flash['error'] = "Invalid registration link."
      redirect_to root_url and return
    end
    # Check that the identity has not already been activated.
    if @identity.activated?
      flash['error'] = "This account has already been activated."
      redirect_to root_url
    end
  end

  def set_identity
    @identity = LocalIdentity.find(params[:id] || params[:local_identity_id])
  end

end
