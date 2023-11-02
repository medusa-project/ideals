# frozen_string_literal: true

class HealthController < ApplicationController

  ##
  # Responds to `GET /health`
  #
  def index
    render plain: "OK"
  end

end
