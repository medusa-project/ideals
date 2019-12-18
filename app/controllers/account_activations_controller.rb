# frozen_string_literal: true

class AccountActivationsController < ApplicationController
  def edit
    identity = Identity.find_by(email: params[:email])
    if identity && !identity.activated? && identity.authenticated?(:activation, params[:id])
      identity.update_attribute(:activated,    true)
      identity.update_attribute(:activated_at, Time.zone.now)
      invitee = Invitee.find_by(email: identity.email)

      identity.update_attribute("invitee_id", invitee.id)
      redirect_to "/", alert: "Account activated!"
    else
      redirect_to root_url, alert: "Invalid activation link"
    end
  end
end
