# frozen_string_literal: true

##
# Handles "phase one" of the password reset process--the phase before user
# identity is known.
#
# "Phase two" of the reset process is handled by {IdentitiesController}.
#
class PasswordResetsController < ApplicationController

  ##
  # Renders the initial reset-password form, containing a single field for
  # email address.
  #
  # Responds to `GET /reset-password`
  #
  def get
  end

  ##
  # Responds to `POST /reset-password`
  #
  def post
    if params.dig(:password_reset, :email).present?
      email = params[:password_reset][:email]&.downcase
      if StringUtils.valid_email?(email)
        if current_institution.key == "uiuc" && StringUtils.uofi_email?(email)
          flash['error'] = "Sorry, we're not able to reset passwords for "\
              "email addresses that are associated with an Illinois NetID. "\
              "If you have forgotten your NetID password, please contact the "\
              "NetID Center."
          redirect_to current_institution.scope_url,
                      allow_other_host: true
        else
          @identity = LocalIdentity.where("LOWER(email) = ?", email).limit(1).first
          if @identity
            @identity.create_reset_digest
            @identity.send_password_reset_email
            flash['success'] = "An email has been sent containing "\
                "instructions to reset your password. If you don't receive "\
                "it soon, check your spam folder."
            redirect_to current_institution.scope_url,
                        allow_other_host: true
          else
            flash['error'] = "No user with this email address has been registered."
            redirect_to reset_password_path
          end
        end
      else
        flash['error'] = "The email address you provided is invalid. "\
            "Please try again."
        render "get", status: :bad_request
      end
    else
      flash['error'] = "No email address was provided. Please try again."
      render "get", status: :bad_request
    end
  end

end
