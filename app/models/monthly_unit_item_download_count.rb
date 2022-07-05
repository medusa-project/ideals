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
  # {MonthlyItemDownloadCount#compile_counts} must be run first.
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
  #                            provided in the arguments. # TODO: dl_count should be count
  #
  def self.for_unit(unit:, start_year:, start_month:, end_year:, end_month:)
    start_time = Time.new(start_year, start_month)
    end_time   = Time.new(end_year, end_month)
    raise ArgumentError, "Start year/month is equal to or later than end year/month" if start_time >= end_time

    sql = "SELECT year, month, count
          FROM monthly_unit_item_download_counts
          WHERE unit_id = $1
            AND ((year = $2 AND month >= $3) OR (year > $4))
            AND ((year = $5 AND month <= $6) OR (year < $7))
          ORDER BY year, month;"
    values = [unit.id, start_year, start_month, start_year,
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

end
