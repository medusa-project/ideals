##
# Handles global, sysadmin-level usage statistics.
#
class UsageController < ApplicationController

  before_action :ensure_institution_host, :ensure_logged_in,
                :authorize_sysadmin
  before_action :store_location, only: :index

  ##
  # Responds to `GET /usage/files` (XHR only).
  #
  def files
    @file_sizes      = Institution.file_sizes
    @total_file_size = @file_sizes.map{ |r| r['sum'].to_i }.sum
    render partial: "files"
  end

  ##
  # Responds to `GET /usage`.
  #
  def index
  end

  ##
  # Responds to `GET /usage/items` (XHR only).
  #
  def items
    @item_counts      = Institution.item_counts
    @total_item_count = @item_counts.map{ |r| r['count'] }.sum
    render partial: "items"
  end


  private

  def authorize_sysadmin
    authorize(Usage)
  end

end
