require "test_helper"

class MonthlyItemDownloadCountTest < ActiveSupport::TestCase

  # collection_download_counts_by_item()

  test "collection_download_counts_by_item() returns correct results with no
  arguments" do
    collection = collections(:collection1)
    MonthlyItemDownloadCount.create!(institution_id: 99999, # fake but doesn't matter
                                     unit_id:        99999, # fake but doesn't matter
                                     collection_id:  collection.id,
                                     item_id:        99999, # fake but doesn't matter
                                     year:           2022,
                                     month:          5,
                                     count:          10)
    MonthlyItemDownloadCount.create!(institution_id: 99999,
                                     unit_id:        99999, # fake but doesn't matter
                                     collection_id:  collection.id,
                                     item_id:        99999, # fake but doesn't matter
                                     year:           2022,
                                     month:          8,
                                     count:          5)

    result = MonthlyItemDownloadCount.collection_download_counts_by_item(collection: collection)
    assert_equal 1, result.length
    assert_equal 15, result[0]['dl_count']
  end

  test "collection_download_counts_by_item() returns correct results when
  supplying start and end times" do
    collection = collections(:collection1)
    MonthlyItemDownloadCount.create!(institution_id: 99999, # fake but doesn't matter
                                     unit_id:        99999, # fake but doesn't matter
                                     collection_id:  collection.id,
                                     item_id:        99999, # fake but doesn't matter
                                     year:           2022,
                                     month:          5,
                                     count:          10)
    MonthlyItemDownloadCount.create!(institution_id: 99999, # fake but doesn't matter
                                     unit_id:        99999, # fake but doesn't matter
                                     collection_id:  collection.id,
                                     item_id:        99999, # fake but doesn't matter
                                     year:           2022,
                                     month:          8,
                                     count:          5)

    result = MonthlyItemDownloadCount.collection_download_counts_by_item(
      collection: collection,
      start_year:  2022,
      start_month: 7,
      end_year:    2022,
      end_month:   12)
    assert_equal 1, result.length
    assert_equal 5, result[0]['dl_count']
  end

  # compile_counts()

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
      where(item_id: item.id).
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

  # increment()

  test "increment() increments the count of an existing row" do
    item  = items(:described)
    now   = Time.now
    year  = now.year
    month = now.month
    MonthlyItemDownloadCount.increment(item)
    MonthlyItemDownloadCount.increment(item)
    assert_equal 2, MonthlyItemDownloadCount.find_by(item_id: item.id,
                                                     year:    year,
                                                     month:   month).count
  end

  test "increment() adds a new row if necessary" do
    item  = items(:described)
    now   = Time.now
    year  = now.year
    month = now.month
    assert !MonthlyItemDownloadCount.exists?(item_id: item.id,
                                             year: year,
                                             month: month)
    MonthlyItemDownloadCount.increment(item)
    assert_equal 1, MonthlyItemDownloadCount.find_by(item_id: item.id,
                                                     year: year,
                                                     month: month).count
  end

  # institution_download_counts_by_item()

  test "institution_download_counts_by_item() returns correct results with no
  arguments" do
    institution = institutions(:uiuc)
    MonthlyItemDownloadCount.create!(institution_id: institution.id,
                                     unit_id:        99999, # fake but doesn't matter
                                     collection_id:  99999, # fake but doesn't matter
                                     item_id:        99999, # fake but doesn't matter
                                     year:           2022,
                                     month:          5,
                                     count:          10)
    MonthlyItemDownloadCount.create!(institution_id: institution.id,
                                     unit_id:        99999, # fake but doesn't matter
                                     collection_id:  99999, # fake but doesn't matter
                                     item_id:        99999, # fake but doesn't matter
                                     year:           2022,
                                     month:          8,
                                     count:          5)

    result = MonthlyItemDownloadCount.institution_download_counts_by_item(institution: institution)
    assert_equal 1, result.length
    assert_equal 15, result[0]['dl_count']
  end

  test "institution_download_counts_by_item() returns correct results when
  supplying start and end times" do
    institution = institutions(:uiuc)
    MonthlyItemDownloadCount.create!(institution_id: institution.id,
                                     unit_id:        99999, # fake but doesn't matter
                                     collection_id:  99999, # fake but doesn't matter
                                     item_id:        99999, # fake but doesn't matter
                                     year:           2022,
                                     month:          5,
                                     count:          10)
    MonthlyItemDownloadCount.create!(institution_id: institution.id,
                                     unit_id:        99999, # fake but doesn't matter
                                     collection_id:  99999, # fake but doesn't matter
                                     item_id:        99999, # fake but doesn't matter
                                     year:           2022,
                                     month:          8,
                                     count:          5)

    result = MonthlyItemDownloadCount.institution_download_counts_by_item(
      institution: institution,
      start_year:  2022,
      start_month: 7,
      end_year:    2022,
      end_month:   12)
    assert_equal 1, result.length
    assert_equal 5, result[0]['dl_count']
  end

  # unit_download_counts_by_item()

  test "unit_download_counts_by_item() returns correct results with no
  arguments" do
    unit = units(:unit1)
    MonthlyItemDownloadCount.create!(institution_id: 99999, # fake but doesn't matter
                                     unit_id:        unit.id,
                                     collection_id:  99999, # fake but doesn't matter
                                     item_id:        99999, # fake but doesn't matter
                                     year:           2022,
                                     month:          5,
                                     count:          10)
    MonthlyItemDownloadCount.create!(institution_id: 99999, # fake but doesn't matter
                                     unit_id:        unit.id,
                                     collection_id:  99999, # fake but doesn't matter
                                     item_id:        99999, # fake but doesn't matter
                                     year:           2022,
                                     month:          8,
                                     count:          5)

    result = MonthlyItemDownloadCount.unit_download_counts_by_item(unit: unit)
    assert_equal 1, result.length
    assert_equal 15, result[0]['dl_count']
  end

  test "unit_download_counts_by_item() returns correct results when
  supplying start and end times" do
    unit = units(:unit1)
    MonthlyItemDownloadCount.create!(institution_id: 99999, # fake but doesn't matter
                                     unit_id:        unit.id,
                                     collection_id:  99999, # fake but doesn't matter
                                     item_id:        99999, # fake but doesn't matter
                                     year:           2022,
                                     month:          5,
                                     count:          10)
    MonthlyItemDownloadCount.create!(institution_id: 99999, # fake but doesn't matter
                                     unit_id:        unit.id,
                                     collection_id:  99999, # fake but doesn't matter
                                     item_id:        99999, # fake but doesn't matter
                                     year:           2022,
                                     month:          8,
                                     count:          5)

    result = MonthlyItemDownloadCount.unit_download_counts_by_item(
      unit:        unit,
      start_year:  2022,
      start_month: 7,
      end_year:    2022,
      end_month:   12)
    assert_equal 1, result.length
    assert_equal 5, result[0]['dl_count']
  end

end
