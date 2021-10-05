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
  # @param email [String] Email address.
  # @return [Boolean] Whether the given email address is related to the U of I.
  #
  def self.uofi_email?(email)
    domain = email.downcase.split("@").last
    ::Configuration.instance.uofi_email_domains.include?(domain)
  end

  ##
  # @param email [String] Email address.
  # @return [Boolean]
  #
  def self.valid_email?(email)
    EMAIL_REGEX.match?(email)
  end

end