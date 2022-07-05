require "test_helper"

class MonthlyCollectionItemDownloadCountTest < ActiveSupport::TestCase

  # compile_counts()

  test "compile_counts() compiles correct counts" do
    item        = items(:multiple_bitstreams)
    collection  = item.primary_collection
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
    MonthlyCollectionItemDownloadCount.compile_counts

    counts = MonthlyCollectionItemDownloadCount.
      where(collection_id: collection.id).
      where("((year = ? AND month >= ?) OR year > ?) AND "\
            "((year = ? AND month <= ?) OR year < ?)",
            start_year, start_month, start_year, end_year, end_month, end_year)
    assert_equal (end_year - start_year + 1) * (end_month - start_month + 1),
                 counts.length
    counts.each do |count|
      assert count.count > 0
    end
  end

  # for_collection()

  test "for_collection() raises an error when start year/month is later than
  end year/month" do
    assert_raises ArgumentError do
      MonthlyCollectionItemDownloadCount.for_collection(collection:  nil,
                                                        start_year:  2022,
                                                        start_month: 1,
                                                        end_year:    2021,
                                                        end_month:   12)
    end
  end

  test "for_collection() returns a correct value" do
    item        = items(:multiple_bitstreams)
    collection  = item.primary_collection
    start_year  = 2018
    start_month = 1
    end_year    = 2020
    end_month   = 12

    (start_year..end_year).each do |year|
      (start_month..end_month).each do |month|
        collection.items.each do |it|
          it.bitstreams.each do |bs|
            bs.events.build(event_type:  Event::Type::DOWNLOAD,
                            happened_at: Time.new(year, month)).save!
          end
        end
      end
    end

    MonthlyItemDownloadCount.compile_counts
    MonthlyCollectionItemDownloadCount.compile_counts

    actual = MonthlyCollectionItemDownloadCount.for_collection(collection:  collection,
                                                               start_year:  start_year,
                                                               start_month: start_month,
                                                               end_year:    end_year,
                                                               end_month:   end_month)
    assert_equal (end_year - start_year + 1) * (end_month - start_month + 1),
                 actual.length
    actual.each do |row|
      assert row['dl_count'] > 0
    end
  end

  # increment()

  test "increment() increments the count of an existing row" do
    collection = collections(:collection1)
    now        = Time.now
    year       = now.year
    month      = now.month
    MonthlyCollectionItemDownloadCount.increment(collection.id)
    MonthlyCollectionItemDownloadCount.increment(collection.id)
    assert_equal 2, MonthlyCollectionItemDownloadCount.find_by(collection_id: collection.id,
                                                               year:          year,
                                                               month:         month).count
  end

  test "increment() adds a new row if necessary" do
    collection = collections(:collection1)
    now        = Time.now
    year       = now.year
    month      = now.month
    assert !MonthlyCollectionItemDownloadCount.exists?(collection_id: collection.id,
                                                       year:          year,
                                                       month:         month)
    MonthlyCollectionItemDownloadCount.increment(collection.id)
    assert_equal 1, MonthlyCollectionItemDownloadCount.find_by(collection_id: collection.id,
                                                               year:          year,
                                                               month:         month).count
  end

end
