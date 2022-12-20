##
# Helper class for converting times and durations.
#
class TimeUtils

  LOGGER = CustomLogger.new(TimeUtils)

  ##
  # Estimates completion time based on a progress percentage.
  #
  # @param start_time [Time]
  # @param percent [Float]
  # @return [Time]
  #
  def self.eta(start_time, percent)
    if percent == 0
      1.year.from_now
    else
      start = start_time.utc
      now = Time.now.utc
      Time.at(start + ((now - start) / percent))
    end
  end

  ##
  # Converts date strings in one of the following formats to ISO 8601:
  #
  # * Month YYYY
  # * Month, YYYY
  # * Month DD YYYY
  # * Month DD, YYYY
  #
  # @param string [String, nil] ISO 8601 date, or nil if the argument format is
  #                             not recognized.
  #
  def self.iso8601(string)
    month_names = %w(January February March April May June July August
                     September October November December)
    iso_str = year = month = day = nil
    # Check for "Month DD YYYY" or "Month DD, YYYY"
    result = string.match(/(#{month_names.join("|")}) (\d{1,2}),? (\d{4})$/)
    if result
      month = (month_names.index(result[1]) + 1).to_s.rjust(2, "0")
      day   = result[2].rjust(2, "0")
      year  = result[3]
    end
    # Check for "Month YYYY" or "Month, YYYY"
    result = string.match(/(#{month_names.join("|")}),? ?(\d{4})$/)
    if result
      month = (month_names.index(result[1]) + 1).to_s.rjust(2, "0")
      year  = result[2]
    end
    if year
      iso_str = "#{year}"
      if month
        iso_str += "-#{month}"
        if day
          iso_str += "-#{day}"
        end
      end
    end
    iso_str
  end

  ##
  # @param seconds [Integer] Duration in seconds.
  # @return [String] String in `HH:MM:SS` format.
  #
  def self.seconds_to_hms(seconds)
    if seconds.to_f != seconds
      raise ArgumentError, "#{seconds} is not in a supported format."
    end
    seconds = seconds.to_f
    # hours
    hr    = seconds / 60.0 / 60.0
    floor = hr.floor
    rem   = hr - floor
    hr    = floor
    # minutes
    min   = rem * 60
    floor = min.floor
    rem   = min - floor
    min   = floor
    # seconds
    sec = rem * 60

    sprintf("%s:%s:%s",
            hr.round.to_s.rjust(2, "0"),
            min.round.to_s.rjust(2, "0"),
            sec.round.to_s.rjust(2, "0"))
  end

  ##
  # Creates a {Time} instance from the given information. If the given year is
  # nil, nil is returned.
  #
  # @param year [Object,nil]  Integer or object that can be converted to one.
  # @param month [Object,nil] Integer or object that can be converted to one.
  # @param day [Object,nil]   Integer or object that can be converted to one.
  # @return [Time,nil]
  #
  def self.ymd_to_time(year, month, day)
    time = nil
    year = year.to_i
    if year > 0
      month = month.present? ? month.to_i : nil
      day   = day.present? ? day.to_i : nil
      time  = Time.new(year, month, day)
    end
    time
  end

end
