# frozen_string_literal: true

class ErrorsController < ApplicationController
  def error404
    respond_to do |format|
      format.html { render "errors/error404", status: :not_found }
      format.all { head :not_found }
    end
  end
end
