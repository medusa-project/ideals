require 'test_helper'

class InstitutionTest < ActiveSupport::TestCase

  setup do
    @instance = institutions(:somewhere)
    assert @instance.valid?
  end

  # download_count_by_month()

  test "download_count_by_month() returns a correct count" do
    @instance = institutions(:uiuc)
    @instance.units.each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.bitstreams.each do |bitstream|
            bitstream.add_download
          end
        end
      end
    end
    assert_equal 1, @instance.download_count_by_month.length
  end

  test "download_count_by_month() returns a correct count when supplying start
  and end times" do
    @instance = institutions(:uiuc)
    @instance.units.each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.bitstreams.each do |bitstream|
            bitstream.add_download
          end
        end
      end
    end

    Event.where(event_type: Event::Type::DOWNLOAD).
      limit(1).
      update_all(created_at: 90.minutes.ago)

    actual = @instance.download_count_by_month(start_time: 2.hours.ago,
                                               end_time:   1.hour.ago)
    assert_equal 1, actual.length
    assert_kind_of Time, actual[0]['month']
    assert_equal 0, actual[0]['dl_count']
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

  # item_download_counts()

  test "item_download_counts() returns correct results with no arguments" do
    @instance = institutions(:uiuc)
    Event.destroy_all
    item_count = 0
    @instance.units.each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.bitstreams.each do |bitstream|
            bitstream.add_download
          end
          # The query won't return items without a title.
          item.elements.build(registered_element: registered_elements(:title),
                              string: "This is the title").save!
          item_count += 1 if item.bitstreams.any?
        end
      end
    end
    result = @instance.item_download_counts
    assert_equal 6, result.length
    assert_equal 24, result[0]['dl_count']
  end

  test "item_download_counts() returns correct results when supplying limit
  and offset" do
    @instance = institutions(:uiuc)
    Event.destroy_all
    @instance.units.each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.bitstreams.each do |bitstream|
            bitstream.add_download
          end
          # The query won't return items without a title.
          item.elements.build(registered_element: registered_elements(:title),
                              string: "This is the title").save!
        end
      end
    end
    result = @instance.item_download_counts(offset: 1, limit: 2)
    assert_equal 2, result.length
    assert_equal 8, result[0]['dl_count']
  end

  test "item_download_counts() returns correct results when supplying start
  and end times" do
    @instance = institutions(:uiuc)
    Event.destroy_all
    @instance.units.each do |unit|
      unit.collections.each do |collection|
        collection.items.each do |item|
          item.bitstreams.each do |bitstream|
            bitstream.add_download
          end
          # The query won't return items without a title.
          item.elements.build(registered_element: registered_elements(:title),
                              string: "This is the title").save!
        end
      end
    end

    # Adjust the created_at property of one of the just-created bitstream
    # download events to fit inside the time window.
    Event.where(event_type: Event::Type::DOWNLOAD).all.first.
      update!(happened_at: 90.minutes.ago)

    result = @instance.item_download_counts(start_time: 2.hours.ago,
                                            end_time:   1.hour.ago)
    assert_equal 1, result.length
    assert_equal 4, result[0]['dl_count']
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

  # name

  test "name must be present" do
    @instance.name = nil
    assert !@instance.valid?
    @instance.name = ""
    assert !@instance.valid?
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

  # users()

  test "users() returns all users" do
    assert @instance.users.count > 0
  end

end
