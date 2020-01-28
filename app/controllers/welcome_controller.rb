# frozen_string_literal: true

class WelcomeController < ApplicationController
  helper_method :current_user, :logged_in?

  def index
    @item_count = Item.count
  end

  def dashboard; end

  def deposit; end

  def login_choice; end

  def on_failed_registration; end
end
