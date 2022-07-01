require "test_helper"

class MonthlyItemDownloadCountTest < ActiveSupport::TestCase

  test "compile_counts() compiles correct counts" do
    item        = items(:multiple_bitstreams)
    start_year  = 2018
    start_month = 1
    end_year    = 2020
    end_month   = 12

    (start_year..end_year).each do |year|
      (start_month..end_month).each do |month|
        item.bitstreams.each do |bs|
          bs.events.build(event_type:  Event::Type::DOWNLOAD,
                          happened_at: Time.new(year, month)).save!
        end
      end
    end

    MonthlyItemDownloadCount.compile_counts

    counts = MonthlyItemDownloadCount.
      where(item: item).
      where("((year = ? AND month >= ?) OR year > ?) AND "\
            "((year = ? AND month <= ?) OR year < ?)",
            start_year, start_month, start_year, end_year, end_month, end_year)
    assert_equal (end_year - start_year + 1) * (end_month - start_month + 1),
                 counts.length
    counts.each do |count|
      assert_equal item.bitstreams.length, count.count
    end
  end

  # for_item()

  test "for_item() raises an error when start year/month is later than end
  year/month" do
    assert_raises ArgumentError do
      MonthlyItemDownloadCount.for_item(item:        nil,
                                        start_year:  2022,
                                        start_month: 1,
                                        end_year:    2021,
                                        end_month:   12)
    end
  end

  test "for_item() returns a correct value" do
    item        = items(:multiple_bitstreams)
    start_year  = 2018
    start_month = 1
    end_year    = 2020
    end_month   = 12

    (start_year..end_year).each do |year|
      (start_month..end_month).each do |month|
        item.bitstreams.each do |bs|
          bs.events.build(event_type:  Event::Type::DOWNLOAD,
                          happened_at: Time.new(year, month)).save!
        end
      end
    end

    MonthlyItemDownloadCount.compile_counts

    actual = MonthlyItemDownloadCount.for_item(item:        item,
                                               start_year:  start_year,
                                               start_month: start_month,
                                               end_year:    end_year,
                                               end_month:   end_month)
    assert_equal (end_year - start_year + 1) * (end_month - start_month + 1),
                 actual.length
    actual.each do |row|
      assert_equal item.bitstreams.length, row['dl_count']
    end
  end

  test "for_item() includes a value for the current month" do
    item        = items(:multiple_bitstreams)
    start_year  = Time.now.year
    start_month = 1
    end_year    = start_year
    end_month   = Time.now.month

    (start_year..end_year).each do |year|
      (start_month..end_month).each do |month|
        item.bitstreams.each do |bs|
          bs.events.build(event_type:  Event::Type::DOWNLOAD,
                          happened_at: Time.new(year, month)).save!
        end
      end
    end

    MonthlyItemDownloadCount.compile_counts

    actual = MonthlyItemDownloadCount.for_item(item:        item,
                                               start_year:  start_year,
                                               start_month: start_month,
                                               end_year:    end_year,
                                               end_month:   end_month)
    assert_equal (end_year - start_year + 1) * (end_month - start_month + 1),
                 actual.length
    assert_equal item.bitstreams.length,
                 actual.find{ |r| r['month'].year == end_year &&
                   r['month'].month == end_month }['dl_count']
  end

end
