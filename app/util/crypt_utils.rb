# frozen_string_literal: true

class CryptUtils

  ##
  # Generates a public certificate from a private key.
  #
  # @param key [String,OpenSSL::PKey::RSA]
  # @param organization [String]
  # @param common_name [String]
  # @param expires_in [Integer] Expiration in seconds from now.
  # @return [OpenSSL::X509::Certificate]
  #
  def self.generate_cert(key:,
                         organization:,
                         common_name:,
                         expires_in: 10.years.to_i)
    raise ArgumentError, "Missing key argument" unless key
    raise ArgumentError, "Missing organization argument" unless organization
    raise ArgumentError, "Missing common_name argument" unless common_name
    raise ArgumentError, "Missing expires_in argument" unless expires_in
    unless key.kind_of?(OpenSSL::PKey::RSA)
      key = OpenSSL::PKey::RSA.new(key)
    end
    name = OpenSSL::X509::Name.parse("/C=US/ST=Illinois/O=#{organization}/CN=#{common_name}")
    cert = OpenSSL::X509::Certificate.new
    cert.version    = 2
    cert.serial     = 0
    cert.not_before = Time.now
    cert.not_after  = Time.now + expires_in
    cert.public_key = key.public_key
    cert.subject    = name
    cert.issuer     = name
    cert.sign(key, OpenSSL::Digest.new("SHA256"))
    cert
  end

  ##
  # Generates a new private key.
  #
  # @return [OpenSSL::PKey::RSA]
  #
  def self.generate_key
    OpenSSL::PKey::RSA.new(4096)
  end

end