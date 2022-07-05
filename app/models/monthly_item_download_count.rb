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
# N.B.: the "soft" foreign keys are not real foreign keys because a row
# represents a month in the past. If `item_id` were a real foreign key, then
# deleting an item would delete all of its historical counts, and reduce those
# of its owning collection, unit, and institution.
#
# * `collection_id`  Soft foreign key to the primary collection of the
#                    [Item].
# * `count`          Download count.
# * `created_at`     Managed by ActiveRecord.
# * `institution_id` Soft foreign key to the institution of the primary
#                    unit of the primary collection of the [Item].
# * `item_id`        Soft foreign key to [Item].
# * `month`          Month number from 1 to 12.
# * `unit_id`        Soft foreign key to the primary unit of the primary
#                    collection of the [Item].
# * `updated_at`     Managed by ActiveRecord.
# * `year`           Year.
#
class MonthlyItemDownloadCount < ApplicationRecord

  EARLIEST_YEAR = 2006

  ##
  # Populates the table with download counts for all items and all months going
  # back to {EARLIEST_YEAR}.
  #
  # This will take many hours to run the first time, but subsequent monthly
  # runs will be much faster.
  #
  def self.compile_counts
    MonthlyItemDownloadCount.delete_all
    now           = Time.now
    current_year  = now.year
    current_month = now.month
    items         = Item.where(stage: Item::Stages::APPROVED)
    Item.uncached do
      ThreadUtils.process_in_parallel(items,
                                      num_threads:    2,
                                      print_progress: true) do |item|
        owning_ids     = item.owning_ids
        institution_id = owning_ids['institution_id']
        unit_id        = owning_ids['unit_id']
        collection_id  = owning_ids['collection_id']
        next unless institution_id && unit_id && collection_id
        count_structs  = MonthlyItemDownloadCount.where(item_id: item.id).pluck(:year, :month)
        (EARLIEST_YEAR..current_year).each do |year|
          (1..12).each do |month|
            # Skip the current month, as it's not over yet.
            break if year == current_year && month == current_month
            # Skip the current item-year-month combo if it already exists.
            count_obj = count_structs.find{ |o| o[0] == year && o[1] == month }
            unless count_obj
              start_time = Time.new(year, month, 1)
              end_time   = start_time + 1.month - 1.second
              struct     = item.download_count_by_month(start_time: start_time,
                                                        end_time:   end_time)
              MonthlyItemDownloadCount.create!(institution_id: institution_id,
                                               unit_id:        unit_id,
                                               collection_id:  collection_id,
                                               item_id:        item.id,
                                               year:           year,
                                               month:          month,
                                               count:          struct[0]['dl_count'].to_i)
            end
          end
        end
      end
    end
  end

  def self.for_collection(collection:,
                          start_year:, start_month:,
                          end_year:, end_month:)
    start_time = Time.new(start_year, start_month)
    end_time   = Time.new(end_year, end_month)
    raise ArgumentError, "Start year/month is equal to or later than end year/month" if start_time >= end_time

    sql = "SELECT year, month, SUM(count) AS count
          FROM monthly_item_download_counts
          WHERE collection_id = $1
            AND ((year = $2 AND month >= $3) OR (year > $4))
            AND ((year = $5 AND month <= $6) OR (year < $7))
          GROUP BY year, month
          ORDER BY year, month;"
    values = [collection.id, start_year, start_month, start_year,
              end_year, end_month, end_year]
    result = self.connection.exec_query(sql, "SQL", values)
    arr    = group_results(result, start_year, start_month, end_year, end_month)

    # This table does not include a value for the current month. If needed, we
    # will add one for the client as a convenience.
    now = Time.now
    if end_year == now.year && end_month >= now.month
      count = collection.download_count_by_month(start_time: Time.new(now.year, now.month),
                                                 end_time:   now)[0]
      arr  << count
    end
    arr
  end

  ##
  # N.B.: the backing table does not include a count for the current month,
  # but if included in the time span of the arguments, this count is obtained
  # from the `events` table instead and included.
  #
  # @param institution [Institution]
  # @param start_year [Integer]
  # @param start_month [Integer]
  # @param end_year [Integer]    Inclusive.
  # @param end_month [Integer]   Inclusive.
  # @return [Enumerable<Hash>] Enumerable of hashes with `month` and `dl_count`
  #                            keys. The length is equal to the month span
  #                            provided in the arguments. # TODO: dl_count should be count
  #
  def self.for_institution(institution:,
                           start_year:, start_month:,
                           end_year:, end_month:)
    start_time = Time.new(start_year, start_month)
    end_time   = Time.new(end_year, end_month)
    raise ArgumentError, "Start year/month is equal to or later than end year/month" if start_time >= end_time

    sql = "SELECT year, month, SUM(count) AS count
          FROM monthly_item_download_counts
          WHERE institution_id = $1
            AND ((year = $2 AND month >= $3) OR (year > $4))
            AND ((year = $5 AND month <= $6) OR (year < $7))
          GROUP BY year, month
          ORDER BY year, month;"
    values = [institution.id, start_year, start_month, start_year,
              end_year, end_month, end_year]
    result = self.connection.exec_query(sql, "SQL", values)
    arr    = group_results(result, start_year, start_month, end_year, end_month)

    # This table does not include a value for the current month. If needed, we
    # will add one for the client as a convenience.
    now = Time.now
    if end_year == now.year && end_month >= now.month
      count = institution.download_count_by_month(start_time: Time.new(now.year, now.month),
                                                  end_time:   now)[0]
      arr  << count
    end
    arr
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
    arr    = group_results(result, start_year, start_month, end_year, end_month)

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

  ##
  # N.B.: the backing table does not include a count for the current month,
  # but if included in the time span of the arguments, this count is obtained
  # from the `events` table instead and included.
  #
  # @param unit [Unit]
  # @param start_year [Integer]
  # @param start_month [Integer]
  # @param end_year [Integer]    Inclusive.
  # @param end_month [Integer]   Inclusive.
  # @return [Enumerable<Hash>] Enumerable of hashes with `month` and `dl_count`
  #                            keys. The length is equal to the month span
  #                            provided in the arguments. # TODO: dl_count should be count
  #
  def self.for_unit(unit:, start_year:, start_month:, end_year:, end_month:)
    start_time = Time.new(start_year, start_month)
    end_time   = Time.new(end_year, end_month)
    raise ArgumentError, "Start year/month is equal to or later than end year/month" if start_time >= end_time

    sql = "SELECT year, month, SUM(count) AS count
          FROM monthly_item_download_counts
          WHERE unit_id = $1
            AND ((year = $2 AND month >= $3) OR (year > $4))
            AND ((year = $5 AND month <= $6) OR (year < $7))
          GROUP BY year, month
          ORDER BY year, month;"
    values = [unit.id, start_year, start_month, start_year,
              end_year, end_month, end_year]
    result = self.connection.exec_query(sql, "SQL", values)
    arr    = group_results(result, start_year, start_month, end_year, end_month)

    # This table does not include a value for the current month. If needed, we
    # will add one for the client as a convenience.
    now = Time.now
    if end_year == now.year && end_month >= now.month
      count = unit.download_count_by_month(start_time: Time.new(now.year, now.month),
                                           end_time:   now)[0]
      arr  << count
    end
    arr
  end

  ##
  # @param item [Item]
  # @return [void]
  #
  def self.increment_for_item(item)
    owning_ids     = item.owning_ids
    institution_id = owning_ids['institution_id']
    unit_id        = owning_ids['unit_id']
    collection_id  = owning_ids['collection_id']
    if institution_id && unit_id && collection_id
      now = Time.now
      transaction do
        count_obj = MonthlyItemDownloadCount.find_by(item_id:        item.id,
                                                     collection_id:  collection_id,
                                                     unit_id:        unit_id,
                                                     institution_id: institution_id,
                                                     year:           now.year,
                                                     month:          now.month)
        if count_obj
          count_obj.update!(count: count_obj.count + 1)
        else
          MonthlyItemDownloadCount.create!(item_id:        item.id,
                                           collection_id:  collection_id,
                                           unit_id:        unit_id,
                                           institution_id: institution_id,
                                           year:           now.year,
                                           month:          now.month,
                                           count:          1)
        end
      end
    end
  end


  ##
  # Private.
  #
  def self.group_results(result_rows, start_year, start_month, end_year, end_month)
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
          row   = result_rows.find{ |row| row['year'] == year && row['month'] == month }
          count = row ? row['count'] : 0
          arr << {
            'month'    => Time.new(year, month),
            'dl_count' => count
          }
        end
      end
    end
    arr
  end

end
