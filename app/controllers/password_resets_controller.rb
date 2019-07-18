# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  before_action :set_identity, only: [:edit, :update]
  before_action :valid_identity, only: [:edit, :update]
  before_action :check_expiration, only: [:edit, :update]

  def new; end

  def create
    @identity = Identity.find_by(email: params[:password_reset][:email].downcase)
    if @identity
      @identity.create_reset_digest
      @identity.send_password_reset_email
      redirect_to root_url, notice: "Email sent with password reset instructions"

    else
      render "new", alert: "Email address not found"
    end
  end

  def edit; end

  def update
    if params[:identity][:password].empty?
      @identity.errors.add(:password, "can't be empty")
      render "edit"
    elsif @identity.update(user_params)
      # assumes data curation network -- when there are other use cases add code branches here
      redirect_to "/data_curation_network", notice: "Password has been reset. Log in here."
    else
      render "edit"
    end
  end

  private

  def identity_params
    params.require(:identity).permit(:password, :password_confirmation)
  end

  def set_identity
    @identity = Identity.find_by(email: params[:email])
  end

  # Confirms a valid user.
  def valid_identity
    unless @identity&.activated? &&
        @identity&.authenticated?(:reset, params[:id])
      redirect_to root_url
    end
  end

  # Checks expiration of reset token.
  def check_expiration
    redirect_to new_password_reset_url, alert: "Password reset has expired." if @identity.password_reset_expired?
  end
end
