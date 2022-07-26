class HealthController < ApplicationController

  ##
  # Responds to `GET /health`
  #
  def index
    render plain: "OK"
  end

end
