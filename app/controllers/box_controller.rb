# frozen_string_literal: true

class BoxController < ApplicationController

  ##
  # Box OAuth2 callback route. Responds to `GET /box/callback`
  #
  def oauth_callback
    raise ActionController::BadRequest, "Missing code" if params[:code].blank?
    code = params[:code].gsub(/^A-Za-z0-9/, "")[0..64]
    BoxClient.new(session).new_access_token(code)
    redirect_to params[:state] || redirect_path
  end

end
