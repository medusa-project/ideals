# frozen_string_literal: true

class StringUtils

  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  ##
  # Performs ROT-18 on a string. This is used to apparently "scramble" them in
  # a way that is easy to reverse.
  #
  # @param str [String] String to encode.
  # @return [String]    Encoded string.
  #
  def self.rot18(str)
    str.tr('A-Ma-m0-4N-Zn-z5-9', 'N-Zn-z5-9A-Ma-m0-4')
  end

  ##
  # @param filename [String]
  # @return [String]
  #
  def self.sanitize_filename(filename)
    filename.gsub(/[\/\\]/, "_")
  end

  ##
  # @param string [String] String to encode.
  # @return [String] URL-encoded string.
  #
  def self.url_encode(string)
    # N.B.: CGI.escape() inserts "+" instead of "%20" which Chrome interprets
    # literally.
    ERB::Util.url_encode(string)
  end

  ##
  # @param string [String] Input string in any encoding.
  # @return [String] UTF-8 string.
  #
  def self.utf8(string)
    Iconv.conv('UTF-8//IGNORE', 'UTF-8', string)
  end

  ##
  # @param email [String] Email address.
  # @return [Boolean]
  #
  def self.valid_email?(email)
    EMAIL_REGEX.match?(email)
  end

end