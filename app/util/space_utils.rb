##
# Helper class for converting spatial coordinates.
#
class SpaceUtils

  ##
  # @param degrees [Integer]
  # @param minutes [Integer]
  # @param seconds [Integer,Float]
  # @return [Float]
  #
  def self.dms_to_decimal(degrees, minutes, seconds)
    degrees = degrees.to_i
    minutes = minutes.to_i
    seconds = seconds.to_f
    sixty_f = 60.to_f
    min_sec = (minutes / sixty_f) + (seconds / sixty_f / sixty_f)
    (degrees > 0) ? degrees + min_sec : degrees - min_sec
  end

end
