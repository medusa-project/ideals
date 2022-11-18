##
# Our demo server is public, but we don't want it to get crawled by search
# engine bots, so this controller provides a dynamic, environment-specific
# `robots.txt` file depending on the current Rails environment.
#
class RobotsController < ApplicationController

  before_action :override_requested_format

  ##
  # Responds to `GET /robots.txt`.
  #
  def show
    render Rails.env.demo? ? "show_demo" : "show"
  end


  private

  def override_requested_format
    request.format = "txt"
  end

end