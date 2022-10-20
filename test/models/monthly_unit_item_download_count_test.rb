require "test_helper"

class MonthlyUnitItemDownloadCountTest < ActiveSupport::TestCase

  # compile_counts()

  test "compile_counts() compiles correct counts" do
    item        = items(:uiuc_multiple_bitstreams)
    unit        = item.primary_collection.primary_unit
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
    MonthlyUnitItemDownloadCount.compile_counts

    counts = MonthlyUnitItemDownloadCount.
      where(unit_id: unit.id).
      where("((year = ? AND month >= ?) OR year > ?) AND "\
            "((year = ? AND month <= ?) OR year < ?)",
            start_year, start_month, start_year, end_year, end_month, end_year)
    assert_equal (end_year - start_year + 1) * (end_month - start_month + 1),
                 counts.length
    counts.each do |count|
      assert count.count > 0
    end
  end

  # for_unit()

  test "for_unit() raises an error when start year/month is later than end
  year/month" do
    assert_raises ArgumentError do
      MonthlyUnitItemDownloadCount.for_unit(unit:        nil,
                                            start_year:  2022,
                                            start_month: 1,
                                            end_year:    2021,
                                            end_month:   12)
    end
  end

  test "for_unit() returns a correct value" do
    unit        = units(:unit1)
    start_year  = 2018
    start_month = 1
    end_year    = 2020
    end_month   = 12

    (start_year..end_year).each do |year|
      (start_month..end_month).each do |month|
        unit.collections.each do |collection|
          collection.items.each do |item|
            item.bitstreams.each do |bs|
              bs.events.build(event_type:  Event::Type::DOWNLOAD,
                              happened_at: Time.new(year, month)).save!
            end
          end
        end
      end
    end

    MonthlyItemDownloadCount.compile_counts
    MonthlyUnitItemDownloadCount.compile_counts

    actual = MonthlyUnitItemDownloadCount.for_unit(unit:        unit,
                                                   start_year:  start_year,
                                                   start_month: start_month,
                                                   end_year:    end_year,
                                                   end_month:   end_month)
    assert_equal (end_year - start_year + 1) * (end_month - start_month + 1),
                 actual.length
    actual.each do |row|
      assert_equal 11, row['dl_count']
    end
  end

  # increment()

  test "increment() increments the count of an existing row" do
    unit  = units(:unit1)
    now   = Time.now
    year  = now.year
    month = now.month
    MonthlyUnitItemDownloadCount.increment(unit.id)
    MonthlyUnitItemDownloadCount.increment(unit.id)
    assert_equal 2, MonthlyUnitItemDownloadCount.find_by(unit_id: unit.id,
                                                         year:    year,
                                                         month:   month).count
  end

  test "increment() adds a new row if necessary" do
    unit  = units(:unit1)
    now   = Time.now
    year  = now.year
    month = now.month
    assert !MonthlyUnitItemDownloadCount.exists?(unit_id: unit.id,
                                                 year:    year,
                                                 month:   month)
    MonthlyUnitItemDownloadCount.increment(unit.id)
    assert_equal 1, MonthlyUnitItemDownloadCount.find_by(unit_id: unit.id,
                                                         year:    year,
                                                         month:   month).count
  end

  # sum_for_unit()

  test "sum_for_unit() raises an error when start year/month is later than end
  year/month" do
    assert_raises ArgumentError do
      MonthlyUnitItemDownloadCount.sum_for_unit(unit:        nil,
                                                start_year:  2022,
                                                start_month: 1,
                                                end_year:    2021,
                                                end_month:   12)
    end
  end

  test "sum_for_unit() returns a correct count when including children" do
    institution = institutions(:empty)
    unit        = Unit.create!(title: "Root Unit", institution: institution)
    subunit     = unit.units.build(title: "Subunit", institution: institution)
    subunit.save!
    year        = 2022
    start_month = 1
    end_month   = 2
    expected    = 0

    (start_month..end_month).each do |month|
      count = 1
      MonthlyUnitItemDownloadCount.create!(unit_id: unit.id,
                                           year:    year,
                                           month:   month,
                                           count:   count)
      expected += count
      MonthlyUnitItemDownloadCount.create!(unit_id: subunit.id,
                                           year:    year,
                                           month:   month,
                                           count:   count)
      expected += count
    end

    actual = MonthlyUnitItemDownloadCount.sum_for_unit(
      unit:             unit,
      start_year:       year,
      start_month:      start_month,
      end_year:         year,
      end_month:        end_month,
      include_children: true)
    assert_equal expected, actual
  end

  test "sum_for_unit() returns a correct count when not including children" do
    institution = institutions(:empty)
    unit        = Unit.create!(title: "Root Unit", institution: institution)
    subunit     = unit.units.build(title: "Subunit", institution: institution)
    subunit.save!
    year        = 2022
    start_month = 1
    end_month   = 2
    expected    = 0

    (start_month..end_month).each do |month|
      count = 1
      MonthlyUnitItemDownloadCount.create!(unit_id: unit.id,
                                           year:    year,
                                           month:   month,
                                           count:   count)
      expected += count
      MonthlyUnitItemDownloadCount.create!(unit_id: subunit.id,
                                           year:    year,
                                           month:   month,
                                           count:   count)
    end

    actual = MonthlyUnitItemDownloadCount.sum_for_unit(
      unit:             unit,
      start_year:       year,
      start_month:      start_month,
      end_year:         year,
      end_month:        end_month,
      include_children: false)
    assert_equal expected, actual
  end

end
