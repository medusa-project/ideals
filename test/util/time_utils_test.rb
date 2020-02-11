require 'test_helper'

class TimeUtilsTest < ActiveSupport::TestCase

  # eta()

  test "eta works" do
    expected = 1.year.from_now
    actual = TimeUtils.eta(5.hours.ago, 0.0)
    assert actual - expected < 1

    expected = 5.hours.from_now
    actual = TimeUtils.eta(5.hours.ago, 0.5)
    assert actual - expected < 1

    expected = 6.hours.from_now
    actual = TimeUtils.eta(2.hours.ago, 0.25)
    assert actual - expected < 1

    expected = 2.hours.from_now
    actual = TimeUtils.eta(6.hours.ago, 0.75)
    assert actual - expected < 1

    expected = Time.now.utc
    actual = TimeUtils.eta(6.hours.ago, 1.0)
    assert actual - expected < 1
  end

  # seconds_to_hms()

  test "seconds_to_hms() with a nil argument raises an ArgumentError" do
    assert_raises ArgumentError do
      TimeUtils.seconds_to_hms(nil)
    end
  end

  test "seconds_to_hms() with an illegal argument raises an ArgumentError" do
    assert_raises ArgumentError do
      #noinspection RubyYardParamTypeMatch
      TimeUtils.seconds_to_hms("23:12")
    end
  end

  test "seconds_to_hms() works" do
    assert_equal "00:00:30", TimeUtils.seconds_to_hms(30)
    assert_equal "00:05:00", TimeUtils.seconds_to_hms(300)
    assert_equal "01:15:02", TimeUtils.seconds_to_hms(4502)
  end

end
