require "test_helper"

class MonthlyInstitutionItemDownloadCountTest < ActiveSupport::TestCase

  # compile_counts()

  test "compile_counts() compiles correct counts" do
    item        = items(:uiuc_multiple_bitstreams)
    institution = item.primary_collection.primary_unit.institution
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
    MonthlyInstitutionItemDownloadCount.compile_counts

    counts = MonthlyInstitutionItemDownloadCount.
      where(institution_id: institution.id).
      where("((year = ? AND month >= ?) OR year > ?) AND "\
            "((year = ? AND month <= ?) OR year < ?)",
            start_year, start_month, start_year, end_year, end_month, end_year)
    assert_equal (end_year - start_year + 1) * (end_month - start_month + 1),
                 counts.length
    counts.each do |count|
      assert count.count > 0
    end
  end

  # for_institution()

  test "for_institution() raises an error when start year/month is later than end
  year/month" do
    assert_raises ArgumentError do
      MonthlyInstitutionItemDownloadCount.for_institution(institution: nil,
                                                          start_year:  2022,
                                                          start_month: 1,
                                                          end_year:    2021,
                                                          end_month:   12)
    end
  end

  test "for_institution() returns a correct value" do
    institution = institutions(:uiuc)
    start_year  = 2018
    start_month = 1
    end_year    = 2019
    end_month   = 12

    (start_year..end_year).each do |year|
      (start_month..end_month).each do |month|
        institution.units.each do |unit|
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
    end

    MonthlyItemDownloadCount.compile_counts
    MonthlyInstitutionItemDownloadCount.compile_counts

    actual = MonthlyInstitutionItemDownloadCount.for_institution(institution: institution,
                                                                 start_year:  start_year,
                                                                 start_month: start_month,
                                                                 end_year:    end_year,
                                                                 end_month:   end_month)
    assert_equal (end_year - start_year + 1) * (end_month - start_month + 1),
                 actual.length
    actual.each do |row|
      assert_equal 20, row['dl_count']
    end
  end

  # increment()

  test "increment() increments the count of an existing row" do
    institution = institutions(:empty)
    now         = Time.now
    year        = now.year
    month       = now.month
    MonthlyInstitutionItemDownloadCount.increment(institution.id)
    MonthlyInstitutionItemDownloadCount.increment(institution.id)
    assert_equal 2, MonthlyInstitutionItemDownloadCount.find_by(institution_id: institution.id,
                                                                year:           year,
                                                                month:          month).count
  end

  test "increment() adds a new row if necessary" do
    institution = institutions(:empty)
    now         = Time.now
    year        = now.year
    month       = now.month
    assert !MonthlyInstitutionItemDownloadCount.exists?(institution_id: institution.id,
                                                        year:           year,
                                                        month:          month)
    MonthlyInstitutionItemDownloadCount.increment(institution.id)
    assert_equal 1, MonthlyInstitutionItemDownloadCount.find_by(institution_id: institution.id,
                                                                year:           year,
                                                                month:          month).count
  end

end
