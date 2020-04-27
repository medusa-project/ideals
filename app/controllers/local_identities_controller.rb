# frozen_string_literal: true

class LocalIdentitiesController < ApplicationController

  before_action :set_identity, only: [:activate, :destroy, :new_password,
                                      :reset_password, :update]
  before_action :validate_identity, only: [:new_password, :reset_password]
  before_action :validate_reset_token, only: [:new_password, :reset_password]

  ##
  # Responds to `PATCH/POST /identities/:id/activate`. Requires a `token` query
  # argument.
  #
  def activate
    if @identity.authenticated?(:activation, params[:token])
      if @identity.activated?
        flash['error'] = "This account has already been activated."
        redirect_back fallback_location: root_path
      else
        @identity.activate
        flash['success'] = "Account activated."
        redirect_back fallback_location: root_path
      end
    else
      flash['error'] = "Invalid activation link."
      redirect_back fallback_location: root_path
    end
  end

  ##
  # Responds to `POST /identities`
  #
  def create
    @identity = LocalIdentity.new(identity_params)

    respond_to do |format|
      if @identity.save
        format.html { redirect_to @identity, notice: "Identity was successfully created." }
        format.json { render :show, status: :created, location: @identity }
      else
        format.html { render :new }
        format.json { render json: @identity.errors, status: :unprocessable_entity }
      end
    end
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
  # Responds to `GET /identities/register`
  #
  def register; end

  ##
  # Processes form submitted from {new_password}. This is like a limited
  # variant of {update} that updates only the password without being logged in.
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
  # Responds to `PATCH/PUT /identities/:id`
  #
  def update
    respond_to do |format|
      if @identity.update(identity_params)
        format.html { redirect_to @identity, notice: "Identity was successfully updated." }
        format.json { render :show, status: :ok, location: @identity }
      else
        format.html { render :edit }
        format.json { render json: @identity.errors, status: :unprocessable_entity }
      end
    end
  end

  ##
  # Responds to `DELETE /identities/:id`
  #
  def destroy
    @identity.destroy!
    respond_to do |format|
      format.html { redirect_to identities_url, notice: "Identity was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def identity_params
    identity_password_params
  end

  def identity_password_params
    params.require(:local_identity).permit(:password, :password_confirmation)
  end

  def set_identity
    @identity = LocalIdentity.find(params[:id] || params[:local_identity_id])
  end

  def validate_identity
    redirect_to root_url unless @identity&.activated?
  end

  def validate_reset_token
    token = params[:token].to_s
    # Validate the token.
    unless @identity.authenticated?(:reset, token)
      flash['error'] = "Invalid token."
      redirect_to root_url and return
    end
    # Validate the token expiration.
    if @identity.password_reset_expired?
      flash['error'] = "This password reset request has expired. Please try again."
      redirect_to reset_password_url
    end
  end

end
