##
# This is a reporting model/table that enables more efficient queries for
# monthly item download counts than the alternative, which would be to query
# the `events` table and sum the counts of each download event (like
# {Item#download_count_by_month} does).
#
# After every month, a batch process is run (typically the
# `downloads:compile_monthly_counts` rake task via cron) which invokes
# {compile_counts}) to populate the table with download counts from that month
# and any earlier months that don't yet have counts. Note that the current
# month is not included, because it is still accumulating downloads. A current
# month count can be obtained from {Item#download_count_by_month}. {for_item}
# will also invoke that method to include the current month's count as a
# convenience.
#
# Attributes
#
# * `count`      Download count.
# * `created_at` Managed by ActiveRecord.
# * `item_id`    Foreign key to [Item].
# * `month`      Month number from 1 to 12.
# * `updated_at` Managed by ActiveRecord.
# * `year`       Year.
#
class MonthlyItemDownloadCount < ApplicationRecord

  EARLIEST_YEAR = 2006

  belongs_to :item

  ##
  # Populates the table with download counts for all items and all months going
  # back to {EARLIEST_YEAR}.
  #
  # This will take many hours to run the first time, but subsequent monthly
  # runs will be much faster.
  #
  def self.compile_counts
    now           = Time.now
    current_year  = now.year
    current_month = now.month
    count         = Item.count
    progress      = Progress.new(count)
    Item.uncached do
      Item.find_each.with_index do |item, index|
        dirty = false
        count_structs = MonthlyItemDownloadCount.where(item: item).pluck(:year, :month)
        (EARLIEST_YEAR..current_year).each do |year|
          (1..12).each do |month|
            # Skip the current month, as it's not over yet.
            break if year == current_year && month == current_month
            count_obj = count_structs.find{ |o| o[0] == year && o[1] == month }
            unless count_obj
              start_time = Time.new(year, month, 1)
              end_time   = start_time + 1.month - 1.second
              struct     = item.download_count_by_month(start_time: start_time,
                                                        end_time:   end_time)
              item.monthly_item_download_counts.build(year:  year,
                                                      month: month,
                                                      count: struct[0]['dl_count'].to_i)
              dirty = true
            end
          end
        end
        item.save! if dirty
        progress.report(index, "Compiling item download counts")
      end
    end
  end

  ##
  # N.B.: the backing table does not include a count for the current month,
  # but if included in the time span of the arguments, this count is obtained
  # from the `events` table instead and included.
  #
  # @param item [Item]
  # @param start_year [Integer]
  # @param start_month [Integer]
  # @param end_year [Integer]    Inclusive.
  # @param end_month [Integer]   Inclusive.
  # @return [Enumerable<Hash>] Enumerable of hashes with `month` and `dl_count`
  #                            keys. The length is equal to the month span
  #                            provided in the arguments. # TODO: dl_count should be count
  #
  def self.for_item(item:, start_year:, start_month:, end_year:, end_month:)
    start_time = Time.new(start_year, start_month)
    end_time   = Time.new(end_year, end_month)
    raise ArgumentError, "Start year/month is equal to or later than end year/month" if start_time >= end_time

    sql = "SELECT year, month, count
          FROM monthly_item_download_counts
          WHERE item_id = $1
            AND ((year = $2 AND month >= $3) OR (year > $4))
            AND ((year = $5 AND month <= $6) OR (year < $7))
          ORDER BY year, month;"
    values = [item.id, start_year, start_month, start_year,
              end_year, end_month, end_year]
    result = self.connection.exec_query(sql, "SQL", values)

    # The result rows are already close to being in the correct format, but
    # they may be missing the edges of the time span in the arguments. So here
    # we will transform them to make sure the whole time span is included (with
    # counts of 0).
    arr = []
    (start_year..end_year).each do |year|
      (1..12).each do |month|
        next if year == start_year && month < start_month
        break if year == end_year && month > end_month
        # This count won't be in the database. We will fetch it in the next step.
        unless year == Time.now.year && month == Time.now.month
          row   = result.find{ |row| row['year'] == year && row['month'] == month }
          count = row ? row['count'] : 0
          arr  << { 'month'    => Time.new(year, month),
                    'dl_count' => count }
        end
      end
    end

    # This table does not include a value for the current month. If needed, we
    # will add one for the client as a convenience.
    now = Time.now
    if end_year == now.year && end_month >= now.month
      count = item.download_count_by_month(start_time: Time.new(now.year, now.month),
                                           end_time:   now)[0]
      arr  << count
    end
    arr
  end

end
