# frozen_string_literal: true

##
# N.B.: see the documentation of {Invitee} for a detailed overview of the
# invitation & registration process.
#
class LocalIdentitiesController < ApplicationController

  before_action :ensure_logged_in, only: [:edit_password, :update_password]
  before_action :ensure_logged_out, except: [:edit_password, :update_password]
  before_action :set_identity
  before_action :authorize_identity, only: [:edit_password, :register, :update,
                                            :update_password]
  before_action :pre_validate_activation, only: :activate
  before_action :pre_validate_password_reset, only: [:new_password,
                                                     :reset_password]
  before_action :setup_registration_view, only: :register
  before_action :pre_validate_registration, only: [:register, :update]
  before_action :validate_current_password, only: :update_password

  ##
  # Supports incoming links from emails after registration.
  #
  # Responds to `GET /identities/:id/activate`
  #
  def activate
    @identity.activate
    redirect_to login_path
  end

  ##
  # Responds to `GET /identities/:id/edit-password` (XHR only)
  #
  def edit_password
    render partial: "local_identities/password_form",
           locals: { identity: @identity }
  end

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
  # Renders the registration form.
  #
  # Responds to `GET /identities/:id/register`. Requires a `token` query
  # argument which supports incoming links from emails.
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

  ##
  # Handles {register registration form} submissions. Invoked only once per
  # unique {LocalIdentity} instance.
  #
  # Responds to `PATCH/PUT /identities/:id`.
  #
  def update
    begin
      @identity.build_user(email:    @identity.email,
                           uid:      @identity.email,
                           name:     @identity.email,
                           type:     LocalUser.to_s) unless @identity.user
      @identity.update!(identity_params)
      @identity.create_activation_digest
      @identity.send_post_registration_email
    rescue => e
      flash['error'] = "#{e}"
      setup_registration_view
      render "register"
    else
      flash['success'] = "Thanks for registering! Check your email for a link "\
          "to log in and start using IDEALS."
      redirect_to root_url
    end
  end

  ##
  # Handles input from the form rendered by {edit_password}.
  #
  # Responds to `PATCH/PUT /identities/:id/update-password` (XHR only)
  #
  def update_password
    begin
      @identity.update!(identity_password_params)
    rescue => e
      render partial: "shared/validation_messages",
             locals: { object: @identity.errors.any? ? @identity : e },
             status: :bad_request
    else
      flash['success'] = "Your password has been changed."
      render "shared/reload"
    end
  end

  private

  def authorize_identity
    @identity ? authorize(@identity) : skip_authorization
  end

  def identity_params
    params.require(:local_identity).permit(:password, :password_confirmation,
                                           user_attributes: [:name, :phone])
  end

  def identity_password_params
    params.require(:local_identity).permit(:password, :password_confirmation)
  end

  def pre_validate_activation
    # Validate the token.
    unless @identity.authenticated?(:activation, params[:token])
      flash['error'] = "Invalid activation link."
      redirect_to root_url and return
    end
    # Check that the identity has not already been activated.
    if @identity.activated?
      flash['error'] = "This account has already been activated."
      redirect_to root_url
    end
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
    unless @identity.authenticated?(:registration, params[:token])
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

  def setup_registration_view
    @user = LocalUser.new
  end

  def validate_current_password
    unless @identity.authenticated?(:password, params[:current_password])
      render partial: "shared/validation_messages",
             locals: { object: RuntimeError.new("Current password is invalid.") },
             status: :bad_request
    end
  end

end
