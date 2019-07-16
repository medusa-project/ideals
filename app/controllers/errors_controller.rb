# frozen_string_literal: true

class ErrorsController < ApplicationController
  def error404
    respond_to do |format|
      format.html { render "errors/error404", status: :not_found }
      format.all { render nothing: true, status: :not_found }
    end
  end

  def error500
    respond_to do |format|
      format.html { render "errors/error500", status: :internal_server_error }
      format.all { render nothing: true, status: :internal_server_error }
    end
  end
end
