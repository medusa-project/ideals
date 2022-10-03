##
# # How styles work in the application
#
# This is a Sprockets-based app, like apps of earlier Rails versions used to
# be. There is a Bootstrap gem specified in the Gemfile and the stylesheet from
# that is imported into the `application.scss`. There are some other global,
# non-institution-specific style overrides in the same folder.
#
# Institution-specific styles are handled differently: an institution can
# choose various colors etc. through the UI, which are injected into its own
# custom stylesheet provided by this controller. This gets overlaid onto the
# base Bootstrap+global custom styles mentioned above.
#
class StylesheetsController < ApplicationController

  before_action :override_requested_format

  ##
  # Responds to `GET /custom-styles`, returning CSS.
  #
  def show
    # TODO: make these customizable
    @active_color            = "#23527c" # uofi-blue-lighter-3
    @footer_background_color = "#13294b" # uofi-blue
    @header_background_color = "#13294b" # uofi-blue
    @link_color              = "#23527c" # uofi-blue-lighter-3
    @link_hover_color        = "#23527c" # uofi-blue-lighter-3
    @primary_color           = "#23527c" # uofi-blue-lighter-3
    @primary_hover_color     = "#05325b" # uofi-blue-lighter-1
  end

  private

  def override_requested_format
    request.format = "css"
  end

end
