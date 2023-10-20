# frozen_string_literal: true

##
# N.B.: see the documentation of {Invitee} for a detailed overview of the
# invitation & registration process.
#
class LocalIdentitiesController < ApplicationController

  before_action :ensure_institution_host
  before_action :ensure_logged_in, only: [:create, :edit_password, :new,
                                          :update_password]
  before_action :ensure_logged_out, except: [:create, :new, :edit_password,
                                             :update_password]
  before_action :set_identity, except: [:create, :new]
  before_action :set_user, only: [:create, :new]
  before_action :authorize_identity, only: [:edit_password, :register, :update,
                                            :update_password]
  before_action :pre_validate_password_reset, only: [:new_password,
                                                     :reset_password]
  before_action :pre_validate_registration, only: [:register, :update]
  before_action :validate_current_password, only: :update_password

  ##
  # Accepts data POSTed from the form rendered by {new} (sysadmins only).
  #
  # Responds to `POST /users/:id/identities`
  #
  def create
    if @user.identity
      raise "This user already has an associated local identity."
    end
    identity = LocalIdentity.new(user:                  @user,
                                 email:                 @user.email,
                                 password:              identity_password_params[:password],
                                 password_confirmation: identity_password_params[:password_confirmation])
    authorize(identity)
    identity.save!
  rescue => e
    render partial: "shared/validation_messages",
           locals:  { object: identity&.errors&.any? ? identity : e },
           status:  :bad_request
  else
    toast!(title:   "Credentials set",
           message: "Local credentials have been set.")
    render "shared/reload"
  end

  ##
  # Responds to `GET /identities/:id/edit-password` (XHR only)
  #
  def edit_password
    render partial: "local_identities/password_form",
           locals: { identity: @identity }
  end

  ##
  # Renders the form on the show-user page for creating a new local identity
  # (sysadmins only). Sysadmins normally log in via some other method (like
  # SAML) but still need the ability to log into other institutions' domains,
  # which they wouldn't be able to do via any other method than local password
  # authentication.
  #
  # Responds to `GET /users/:id/identities/new`.
  #
  def new
    @identity = LocalIdentity.new(user: @user)
    authorize(@identity)
    render partial: "local_identities/create_form",
           locals: { identity: @identity }
  end

  ##
  # Renders the "phase two" reset-password form, containing password and
  # password confirmation fields. (The "phase one" form is handled by
  # [PasswordResetsController].)
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
    @token = params[:token]
    @user  = User.new
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
      raise "Incorrect math question response. Please try again." unless check_captcha
      user = @identity.user
      if @identity.user.invitee.institution_admin &&
          !user.institution.administering_users.include?(user)
        user.institution.administering_users << user
        user.institution.save!
      end
      @identity.update!(identity_params)
      @identity.update!(registration_digest: nil)
      @identity.send_post_registration_email
    rescue => e
      flash['error'] = "#{e}"
      redirect_to local_identity_register_path(@identity, token: params[:token])
    else
      flash['success'] = "Thanks for registering for "\
                         "#{@identity.user.institution.service_name}! "\
                         "You may now log in."
      redirect_to @identity.user.institution.scope_url,
                  allow_other_host: true
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
      toast!(title:   "Password changed",
             message: "Your password has been changed.")
      render "shared/reload"
    end
  end

  private

  def authorize_identity
    @identity ? authorize(@identity) : skip_authorization
  end

  def identity_params
    params.require(:local_identity).permit(:password, :password_confirmation,
                                           user_attributes: [:name])
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
    if @identity.registration_digest.blank?
      # Prevent access to the registration form by users with no registration
      # digest.
      redirect_to root_url and return
    elsif !@identity.authenticated?(:registration, params[:token])
      flash['error'] = "Invalid registration link."
      redirect_to root_url and return
    end
  end

  def set_identity
    @identity = LocalIdentity.find(params[:id] || params[:local_identity_id])
  end

  def set_user
    @user = User.find(params[:user_id])
  end

  def validate_current_password
    unless @identity.authenticated?(:password, params[:current_password])
      render partial: "shared/validation_messages",
             locals: { object: RuntimeError.new("Current password is invalid.") },
             status: :bad_request
    end
  end

end
