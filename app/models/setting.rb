##
# Encapsulates a key-value setting. Keys should be one of the {Setting::Key}
# constant values. Values are stored as JSON in the database. Simple values can
# be accessed using the {boolean}, {integer}, or {string} class methods.
#
# # Attributes
#
# `created_at` Managed by ActiveRecord.
# `key`        Key.
# `updated_at` Managed by ActiveRecord.
# `value`      JSON-encoded value.
#
class Setting < ApplicationRecord

  class Key
    # String
    BANNER_MESSAGE           = "banner_message"
    # Allowed values: info, warning, danger
    BANNER_MESSAGE_TYPE      = "banner_message.type"
    # Used in global search context. Not used in a scoped context, where
    # {Institution#earliest_search_year} is used instead.
    EARLIEST_SEARCH_YEAR     = "earliest_search_year"
    # Feedback email used in global context and for sending e.g. error emails
    # to.
    FEEDBACK_EMAIL           = "feedback_email"
    # Number of years for which newly generated SAML public certificates are
    # valid.
    SAML_CERT_VALIDITY_YEARS = "saml_cert.expiry_years"
  end

  validates :key, presence: true, uniqueness: { case_sensitive: false }

  ##
  # @param key [String]
  # @param default [Boolean] Value to return if there is no value for the given
  #                          key.
  # @return [Boolean] Value associated with the given key as a boolean, or nil
  #                   if there is no value associated with the given key.
  #
  def self.boolean(key, default = nil)
    v = value_for(key)
    v ? ['true', '1', true, 1].include?(v) : default
  end

  ##
  # @param key [String]
  # @param default [Boolean] Value to return if there is no value for the given
  #                          key.
  # @return [Integer] Value associated with the given key as an integer, or nil
  #                   if there is no value associated with the given key.
  #
  def self.integer(key, default = nil)
    v = value_for(key)
    v ? v.to_i : default
  end

  ##
  # @param key [String]
  # @param value [Object]
  # @return [Option]
  #
  def self.set(key, value)
    option = Setting.find_by_key(key)
    if option # if the option already exists
      if option.value != value # and it has a new value
        option.update!(value: value)
      end
    else # it doesn't exist, so create it
      option = Setting.create!(key: key, value: value)
    end
    option
  end

  ##
  # @param key [String]
  # @param default [Boolean] Value to return if there is no value for the given
  #                          key.
  # @return [String,nil] Value associated with the given key as a string, or nil
  #                      if there is no value associated with the given key.
  #
  def self.string(key, default = nil)
    v = value_for(key)
    v ? v.to_s : default
  end

  ##
  # @private
  #
  def self.value_for(key)
    opt = Setting.where(key: key).limit(1).first
    opt&.value
  end

  ##
  # @return [Object] Raw value.
  #
  def value
    JSON.parse(read_attribute(:value))
  end

  ##
  # @param value [Object] Raw value to set.
  #
  def value=(value)
    write_attribute(:value, JSON.generate(value))
  end

end
