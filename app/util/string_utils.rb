class StringUtils

  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  ##
  # @param email [String] Email address.
  # @return [Boolean]
  #
  def self.valid_email?(email)
    EMAIL_REGEX.match?(email)
  end

end