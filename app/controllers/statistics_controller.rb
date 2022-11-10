##
# Handles global, sysadmin-level statistics.
#
class StatisticsController < ApplicationController

  before_action :ensure_logged_in, :authorize_sysadmin
  before_action :store_location, only: :index

  ##
  # Responds to `GET /statistics/files` (XHR only).
  #
  def files
    @file_sizes      = Institution.file_sizes
    @total_file_size = @file_sizes.map{ |r| r['sum'] }.sum
    render partial: "files"
  end

  ##
  # Responds to `GET /statistics`.
  #
  def index
  end

  ##
  # Responds to `GET /statistics/items` (XHR only).
  #
  def items
    @item_counts      = Institution.item_counts
    @total_item_count = @item_counts.map{ |r| r['count'] }.sum
    render partial: "items"
  end


  private

  def authorize_sysadmin
    authorize(Statistic)
  end

end
