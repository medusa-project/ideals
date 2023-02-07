class SettingsController < ApplicationController

  before_action :ensure_logged_in
  before_action :authorize
  before_action :store_location, only: :index

  ##
  # Responds to `GET /settings`
  #
  def index
  end

  ##
  # Responds to PATCH `/settings`
  #
  def update
    begin
      ActiveRecord::Base.transaction do
        params[:settings].to_unsafe_hash.each_key do |key|
          Setting.set(key, params[:settings][key])
        end
      end
    rescue => e
      handle_error(e)
      render :index
    else
      toast!(title:   "Settings updated",
             message: "Settings have been updated.")
      redirect_to settings_path
    end
  end


  private

  def authorize
    super(nil)
  end

end
