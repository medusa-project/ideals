class RegisteredElementsController < ApplicationController

  before_action :authorize_user

  ##
  # Responds to GET /elements
  #
  def index
    @elements = RegisteredElement.all.order(:name)
  end

end
