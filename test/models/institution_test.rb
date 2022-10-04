require 'test_helper'

class InstitutionTest < ActiveSupport::TestCase

  setup do
    @instance = institutions(:southwest)
    assert @instance.valid?
  end

  # default()

  test "default() returns the default institution" do
    assert_equal institutions(:uiuc), Institution.default
  end

  # create()

  test "create() adds default elements" do
    institution = Institution.create!(name:   "New Institution",
                                      key:    "new",
                                      fqdn:   "example.net",
                                      org_dn: "example")
    assert_equal 27, institution.registered_elements.count
  end

  test "create() adds a default metadata profile" do
    institution = Institution.create!(name:   "New Institution",
                                      key:    "new",
                                      fqdn:   "example.net",
                                      org_dn: "example")
    assert_equal 1, institution.metadata_profiles.count
    profile = institution.metadata_profiles.first
    assert profile.default
    assert profile.elements.count > 0
  end

  test "create() adds a default submission profile" do
    institution = Institution.create!(name:   "New Institution",
                                      key:    "new",
                                      fqdn:   "example.net",
                                      org_dn: "example")
    assert_equal 1, institution.submission_profiles.count
    profile = institution.submission_profiles.first
    assert profile.default
    assert profile.elements.count > 0
  end

  # download_count_by_month()

  test "download_count_by_month() raises an error if start_time > end_time" do
    assert_raises ArgumentError do
      @instance.download_count_by_month(start_time: Time.now,
                                        end_time:   Time.now - 1.day)
    end
  end

  test "download_count_by_month() returns a correct count" do
    Event.destroy_all
    @instance = institutions(:uiuc)
    expected  = 0
    @instance.units.each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.bitstreams.each do |bitstream|
            bitstream.add_download
            expected += 1
          end
        end
      end
    end
    actual = @instance.download_count_by_month
    assert_equal 1, actual.length
    assert_kind_of Time, actual[0]['month']
    assert_equal expected, actual[0]['dl_count']
  end

  test "download_count_by_month() returns a correct count when supplying start
  and end times" do
    @instance = institutions(:uiuc)
    expected = 0
    @instance.units.each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.bitstreams.each do |bitstream|
            bitstream.add_download
            expected += 1
          end
        end
      end
    end

    # Shift all of the events that were just created 3 months into the past.
    Event.update_all(happened_at: 3.months.ago)

    @instance.units.each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.bitstreams.each do |bitstream|
            bitstream.add_download
          end
        end
      end
    end

    actual = @instance.download_count_by_month(start_time: 4.months.ago,
                                               end_time:   2.months.ago)
    assert_equal 3, actual.length
    assert_kind_of Time, actual[0]['month']
    assert_equal expected, actual[1]['dl_count']
  end

  # footer_background_color

  test "footer_background_color must contain a valid CSS color" do
    @instance.footer_background_color = "#r8z8d8"
    assert !@instance.valid?
    @instance.footer_background_color = "#3b7a9c"
    assert @instance.valid?
  end

  # fqdn

  test "fqdn must be present" do
    @instance.fqdn = nil
    assert !@instance.valid?
    @instance.fqdn = ""
    assert !@instance.valid?
  end

  test "fqdn must be a valid FQDN" do
    @instance.fqdn = "-invalid_"
    assert !@instance.valid?
    @instance.fqdn = "host-name.example.org"
    assert @instance.valid?
  end

  # header_background_color

  test "header_background_color must contain a valid CSS color" do
    @instance.header_background_color = "#r8z8d8"
    assert !@instance.valid?
    @instance.header_background_color = "#3b7a9c"
    assert @instance.valid?
  end

  # key

  test "key must be present" do
    @instance.key = nil
    assert !@instance.valid?
    @instance.key = ""
    assert !@instance.valid?
  end

  test "key cannot be changed" do
    assert_raises ActiveRecord::RecordInvalid do
      @instance.update!(key: "newvalue")
    end
  end

  # link_color

  test "link_color must contain a valid CSS color" do
    @instance.link_color = "#r8z8d8"
    assert !@instance.valid?
    @instance.link_color = "#3b7a9c"
    assert @instance.valid?
  end

  # link_hover_color

  test "link_hover_color must contain a valid CSS color" do
    @instance.link_hover_color = "#r8z8d8"
    assert !@instance.valid?
    @instance.link_hover_color = "#3b7a9c"
    assert @instance.valid?
  end

  # name

  test "name must be present" do
    @instance.name = nil
    assert !@instance.valid?
    @instance.name = ""
    assert !@instance.valid?
  end

  # primary_color

  test "primary_color must contain a valid CSS color" do
    @instance.primary_color = "#r8z8d8"
    assert !@instance.valid?
    @instance.primary_color = "#3b7a9c"
    assert @instance.valid?
  end

  # primary_hover_color

  test "primary_hover_color must contain a valid CSS color" do
    @instance.primary_hover_color = "#r8z8d8"
    assert !@instance.valid?
    @instance.primary_hover_color = "#3b7a9c"
    assert @instance.valid?
  end

  # save()

  test "save() updates the instance properties" do
    @instance.org_dn = "o=New Name,dc=new,dc=edu"
    @instance.save!
    assert_equal "new", @instance.key
    assert_equal "New Name", @instance.name
  end

  test "save() sets all other instances as not-default when the instance is set
  as default" do
    Institution.update_all(default: false)
    @instance = Institution.all.first
    @instance.default = true
    @instance.save!
    assert_equal @instance, Institution.find_by_default(true)
  end

  # url()

  test "url() returns a correct URL" do
    assert_equal "https://#{@instance.fqdn}", @instance.url
  end

end
