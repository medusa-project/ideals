# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  before_action :set_identity, only: [:edit, :update]
  before_action :valid_identity, only: [:edit, :update]
  before_action :check_expiration, only: [:edit, :update]

  ##
  # Responds to `POST /reset-password`
  #
  def create
    if params[:password_reset] && params[:password_reset][:email].present?
      email = params[:password_reset][:email]&.downcase
      if StringUtils.valid_email?(email)
        if Identity.uofi?(email)
          flash['error'] = "Sorry, we're not able to reset passwords for "\
              "email addresses that are associated with an Illinois NetID. "\
              "If you have forgotten your NetID password, please contact the "\
              "NetID Center."
          redirect_to root_path
        else
          @identity = Identity.find_by(email: email)
          if @identity
            @identity.create_reset_digest
            @identity.send_password_reset_email
            flash['success'] = "An email has been sent containing "\
                "instructions to reset your password. If you don't receive "\
                "it soon, check your spam folder."
            redirect_to root_url
          else
            flash['error'] = "No user with this email address has been registered."
            redirect_to new_password_reset_path
          end
        end
      else
        flash['error'] = "The email address you provided is invalid. "\
            "Please try again."
        render "new", status: :bad_request
      end
    else
      flash['error'] = "No email address was provided. Please try again."
      redirect_to new_password_reset_path, status: :bad_request
    end
  end

  ##
  # Renders the reset-password form, containing password and password
  # confirmation fields.
  #
  # Responds to `GET /reset-password/:token/edit`
  #
  def edit; end

  ##
  # Renders the initial reset-password form, containing a single field for
  # email address.
  #
  # Responds to `GET /reset-password/new`
  #
  def new; end

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
