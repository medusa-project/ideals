class StringUtils

  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

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