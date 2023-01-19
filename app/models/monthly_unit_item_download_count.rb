##
# This is a reporting model/table that enables more efficient queries for
# monthly item download counts within units than the alternative, which would
# be to query the `events` table and sum the counts of each download event
# (like {Unit#download_count_by_month} does).
#
# The data in this table is derived from that in `monthly_item_download_counts`
# using {compile_counts}. So, that table must be populated first. See
# [MonthlyItemDownloadCount] for more information.
#
# Attributes
#
# * `count`      Download count.
# * `created_at` Managed by ActiveRecord.
# * `month`      Month number from 1 to 12.
# * `unit_id`    Soft foreign key to the [Unit].
# * `updated_at` Managed by ActiveRecord.
# * `year`       Year.
#
class MonthlyUnitItemDownloadCount < ApplicationRecord

  ##
  # This only has to be run once, during the migration process out of DSpace.
  # And {MonthlyItemDownloadCount#compile_counts} must be run first.
  #
  def self.compile_counts
    MonthlyUnitItemDownloadCount.delete_all

    sql = "INSERT INTO monthly_unit_item_download_counts(
              unit_id, year, month, count, created_at, updated_at)
          SELECT unit_id, year, month, SUM(count) AS count, NOW(), NOW()
          FROM monthly_item_download_counts
          GROUP BY unit_id, year, month
          ORDER BY unit_id;"
    self.connection.execute(sql, "SQL")
  end

  ##
  # @param unit [Unit]
  # @param start_year [Integer]
  # @param start_month [Integer]
  # @param end_year [Integer]    Inclusive.
  # @param end_month [Integer]   Inclusive.
  # @return [Enumerable<Hash>] Enumerable of hashes with `month` and `dl_count`
  #                            keys. The length is equal to the month span
  #                            provided in the arguments.
  #
  def self.for_unit(unit:, start_year:, start_month:, end_year:, end_month:)
    start_time = Time.new(start_year, start_month)
    end_time   = Time.new(end_year, end_month)
    raise ArgumentError, "Start year/month is equal to or later than end year/month" if start_time >= end_time
    unit_ids   = unit.all_child_ids + [unit.id]

    sql    = "SELECT year, month, SUM(count) AS count
          FROM monthly_unit_item_download_counts
          WHERE unit_id IN (#{unit_ids.join(",")})
            AND ((year = $1 AND month >= $2) OR (year > $3))
            AND ((year = $4 AND month <= $5) OR (year < $6))
          GROUP BY year, month
          ORDER BY year, month;"
    values = [start_year, start_month, start_year,
              end_year, end_month, end_year]
    result = self.connection.exec_query(sql, "SQL", values)
    MonthlyItemDownloadCount.pad_results(
      result, start_year, start_month, end_year, end_month)
  end

  ##
  # Atomically increments the download count of the [Unit] with the given ID.
  #
  # @param unit_id [Integer]
  # @return [void]
  #
  def self.increment(unit_id)
    now = Time.now
    sql = "INSERT INTO monthly_unit_item_download_counts (unit_id, year, month, count, created_at, updated_at)
          VALUES (#{unit_id}, #{now.year}, #{now.month}, 1, NOW(), NOW())
          ON CONFLICT (unit_id, year, month) DO
          UPDATE SET count = monthly_unit_item_download_counts.count + 1;"
    self.connection.execute(sql, "SQL")
  end

  ##
  # Similar to {for_unit}, but returns a summed count of all months included in
  # the range, instead of monthly counts.
  #
  # @param unit [Unit]
  # @param start_year [Integer]
  # @param start_month [Integer]
  # @param end_year [Integer]         Inclusive.
  # @param end_month [Integer]        Inclusive.
  # @param include_children [Boolean] Whether to include child units in the
  #                                   count.
  # @return [Integer]                 The count.
  #
  def self.sum_for_unit(unit:,
                        start_year:       nil,
                        start_month:      nil,
                        end_year:         nil,
                        end_month:        nil,
                        include_children: true)
    start_year  ||= MonthlyItemDownloadCount::EARLIEST_YEAR
    start_month ||= 1
    end_year    ||= Time.now.year
    end_month   ||= 12
    start_time    = Time.new(start_year, start_month)
    end_time      = Time.new(end_year, end_month)
    raise ArgumentError, "Start year/month is equal to or later than end year/month" if start_time >= end_time

    ids = [unit.id]
    ids += unit.all_child_ids if include_children
    sql = "SELECT SUM(count) AS count
          FROM monthly_unit_item_download_counts
          WHERE unit_id IN (#{ids.join(",")})
            AND ((year = $1 AND month >= $2) OR (year > $3))
            AND ((year = $4 AND month <= $5) OR (year < $6));"
    values = [start_year, start_month, start_year,
              end_year, end_month, end_year]
    result = self.connection.exec_query(sql, "SQL", values)
    result[0]['count'].to_i
  end

end
