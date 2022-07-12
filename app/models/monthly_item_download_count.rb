##
# This is a reporting model/table that enables more efficient queries for
# monthly item download counts than the alternative, which would be to query
# the `events` table and sum the counts of each download event (like
# {Item#download_count_by_month} does).
#
# This is also a source table for some other reporting tables:
# `monthly_collection_item_download_counts`,
# `monthly_unit_item_download_counts`, and
# `monthly_institution_item_download_counts`.
#
# Attributes
#
# N.B.: the "soft" foreign keys are not real foreign keys because a row
# represents a month in the past. If `item_id` were a real foreign key, then
# deleting an item would delete all of its historical counts, and reduce those
# of its owning entities.
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
  # Returns a list of item IDs with their corresponding download counts,
  # ordered by download count descending.
  #
  # @param collection [Collection]
  # @param start_year [Integer]
  # @param start_month [Integer]
  # @param end_year [Integer]  Inclusive.
  # @param end_month [Integer] Inclusive.
  # @return [Enumerable<Hash>] Enumerable of hashes with `item_id` and
  #                            `dl_count` keys.
  #
  def self.collection_download_counts_by_item(collection:,
                                              start_year:  nil,
                                              start_month: nil,
                                              end_year:    nil,
                                              end_month:   nil,
                                              limit:       100)
    sql = StringIO.new
    sql << "SELECT item_id AS id, SUM(count) AS dl_count
            FROM monthly_item_download_counts
            WHERE collection_id = $1
            AND count > 0 "
    sql << "AND ((year = #{start_year} AND month >= #{start_month}) OR (year > #{start_year})) " if start_year
    sql << "AND ((year = #{end_year} AND month <= #{end_month}) OR (year < #{end_year})) " if end_year
    sql << "GROUP BY item_id
            ORDER BY dl_count DESC
            LIMIT #{limit};"
    values = [collection.id]
    self.connection.exec_query(sql.string, 'SQL', values)
  end

  ##
  # Populates the table with download counts for all items and all months going
  # back to {EARLIEST_YEAR}.
  #
  # This will take many hours to run, but only has to be run once, during the
  # migration process out of DSpace.
  #
  def self.compile_counts
    MonthlyItemDownloadCount.delete_all
    now           = Time.now
    current_year  = now.year
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
            # Skip the current item-year-month combo if it already exists.
            count_obj = count_structs.find{ |o| o[0] == year && o[1] == month }
            unless count_obj
              start_time = Time.new(year, month, 1)
              end_time   = start_time + 1.month - 1.second
              struct     = item.download_count_by_month(start_time: start_time,
                                                        end_time:   end_time)
              begin
                MonthlyItemDownloadCount.create!(institution_id: institution_id,
                                                 unit_id:        unit_id,
                                                 collection_id:  collection_id,
                                                 item_id:        item.id,
                                                 year:           year,
                                                 month:          month,
                                                 count:          struct[0]['dl_count'].to_i)
              rescue ActiveRecord::RecordNotUnique
              end
            end
          end
        end
      end
    end
  end

  ##
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
    pad_results(result, start_year, start_month, end_year, end_month)
  end

  ##
  # Atomically increments the download count of the given [Item].
  #
  # @param item [Item]
  # @return [void]
  #
  def self.increment(item)
    owning_ids     = item.owning_ids
    institution_id = owning_ids['institution_id']
    unit_id        = owning_ids['unit_id']
    collection_id  = owning_ids['collection_id']
    if institution_id && unit_id && collection_id
      now = Time.now
      sql = "INSERT INTO monthly_item_download_counts
                (institution_id, unit_id, collection_id, item_id,
                 year, month, count, created_at, updated_at)
            VALUES (#{institution_id}, #{unit_id}, #{collection_id}, #{item.id},
                    #{now.year}, #{now.month}, 1, NOW(), NOW())
            ON CONFLICT (institution_id, unit_id, collection_id, item_id, year, month) DO
            UPDATE SET count = monthly_item_download_counts.count + 1;"
      self.connection.execute(sql, "SQL")
    end
  end

  ##
  # Returns a list of item IDs with their corresponding download counts,
  # ordered by download count descending.
  #
  # @param institution [Institution]
  # @param start_year [Integer]
  # @param start_month [Integer]
  # @param end_year [Integer]  Inclusive.
  # @param end_month [Integer] Inclusive.
  # @return [Enumerable<Hash>] Enumerable of hashes with `item_id` and
  #                            `dl_count` keys.
  #
  def self.institution_download_counts_by_item(institution:,
                                               start_year:  nil,
                                               start_month: nil,
                                               end_year:    nil,
                                               end_month:   nil,
                                               limit:       100)
    sql = StringIO.new
    sql << "SELECT item_id AS id, SUM(count) AS dl_count
            FROM monthly_item_download_counts
            WHERE institution_id = $1
            AND count > 0 "
    sql << "AND ((year = #{start_year} AND month >= #{start_month}) OR (year > #{start_year})) " if start_year
    sql << "AND ((year = #{end_year} AND month <= #{end_month}) OR (year < #{end_year})) " if end_year
    sql << "GROUP BY item_id
            ORDER BY dl_count DESC
            LIMIT #{limit};"
    values = [institution.id]
    self.connection.exec_query(sql.string, 'SQL', values)
  end

  ##
  # The result rows from {for_item} are already close to being in the correct
  # format, but they may be missing the edges of the time span in the
  # arguments. This method transforms them to make sure the whole time span is
  # included (with counts of 0).
  #
  def self.pad_results(result_rows, start_year, start_month, end_year, end_month)
    arr = []
    (start_year..end_year).each do |year|
      (1..12).each do |month|
        next if year == start_year && month < start_month
        break if year == end_year && month > end_month
        row   = result_rows.find{ |row| row['year'] == year && row['month'] == month }
        count = row ? row['count'] : 0
        arr << {
          'month'    => Time.new(year, month),
          'dl_count' => count
        }
      end
    end
    arr
  end

  ##
  # Returns a list of item IDs with their corresponding download counts,
  # ordered by download count descending.
  #
  # @param unit [Unit]
  # @param start_year [Integer]
  # @param start_month [Integer]
  # @param end_year [Integer]  Inclusive.
  # @param end_month [Integer] Inclusive.
  # @return [Enumerable<Hash>] Enumerable of hashes with `item_id` and
  #                            `dl_count` keys.
  #
  def self.unit_download_counts_by_item(unit:,
                                        start_year:  nil,
                                        start_month: nil,
                                        end_year:    nil,
                                        end_month:   nil,
                                        limit:       100)
    sql = StringIO.new
    sql << "SELECT item_id AS id, SUM(count) AS dl_count
            FROM monthly_item_download_counts
            WHERE unit_id = $1
            AND count > 0 "
    sql << "AND ((year = #{start_year} AND month >= #{start_month}) OR (year > #{start_year})) " if start_year
    sql << "AND ((year = #{end_year} AND month <= #{end_month}) OR (year < #{end_year})) " if end_year
    sql << "GROUP BY item_id
            ORDER BY dl_count DESC
            LIMIT #{limit};"
    values = [unit.id]
    self.connection.exec_query(sql.string, 'SQL', values)
  end

end
