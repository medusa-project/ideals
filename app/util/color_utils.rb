class ColorUtils

  ##
  # @param string [String] CSS color.
  # @return [Boolean]
  #
  def self.css_color?(string)
    return false if string.blank?
    string.match?(/^#[a-f0-9]{3}$/) ||                                           # 3-digit hex
      string.match?(/^#[a-f0-9]{6}$/) ||                                         # 6-digit hex
      string.match?(/^rgb\(\d{1,3}%?, *\d{1,3}%?, *\d{1,3}%?\)$/) ||             # rgb()
      string.match?(/^rgba\(\d{1,3}%?, *\d{1,3}%?, *\d{1,3}%?, *\d?.?\d?\)$/) || # rgba()
      string.match?(/^[a-z]+$/)                                                  # color name
  end

  ##
  # Returns a color (either black or white) with the greatest contrast against
  # the given color.
  #
  # @param color [String] CSS color.
  # @return [String] CSS color.
  #
  def self.maximize_text_contrast(color)
    rgb = to_rgb(color)
    avg = rgb.sum / 3.0
    (avg > 127) ? "#000000" : "#ffffff"
  end

  ##
  # @param color [String] CSS color.
  # @return [Array] Three-element array of alpha-premultiplied RGB integer
  #                 values in the range 0-255.
  #
  def self.to_rgb(color)
    if color.start_with?("#")
      if color.length == 4
        r = "#{color[1]}0".to_i(16)
        g = "#{color[2]}0".to_i(16)
        b = "#{color[3]}0".to_i(16)
      elsif color.length == 7
        r = color[1..2].to_i(16)
        g = color[3..4].to_i(16)
        b = color[5..6].to_i(16)
      else
        raise ArgumentError, "Unsupported argument value: #{color}"
      end
      return [r, g, b]
    elsif color.start_with?("rgb(")
      matches = color.match(/rgb\((\d+), *(\d+), *(\d+)\)/)
      return matches.to_a[1..].map(&:to_i)
    elsif color.start_with?("rgba(")
      matches = color.match(/rgba\((\d+), *(\d+), *(\d+), *(\d*.?\d+)\)/)
      # in the map block we premultiply alpha against a white background
      return matches.to_a[1..3].map{ |c| (c.to_i * (1 - matches[4].to_f)).round }
    end
    raise ArgumentError, "Unsupported argument value: #{color}"
  end

end