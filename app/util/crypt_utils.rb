# frozen_string_literal: true

class CryptUtils

  ##
  # @param der [String] Base64-encoded DER certificate.
  # @return [String] PEM-format certificate.
  #
  def self.der_to_pem(der)
    "-----BEGIN CERTIFICATE-----\n" + der + "\n-----END CERTIFICATE-----"
  end

  ##
  # Generates a public certificate from a private key.
  #
  # @param key [String,OpenSSL::PKey::RSA]
  # @param organization [String]
  # @param common_name [String]
  # @param not_before [Time] Time at which the certificate becomes valid.
  # @param not_after [Time] Time after which the certificate is no longer
  #                         valid.
  # @return [OpenSSL::X509::Certificate]
  #
  def self.generate_cert(key:,
                         organization:,
                         common_name:,
                         not_before: Time.now,
                         not_after:)
    raise ArgumentError, "Missing key argument" unless key
    raise ArgumentError, "Missing organization argument" unless organization
    raise ArgumentError, "Missing common_name argument" unless common_name
    raise ArgumentError, "Missing not_before argument" unless not_before
    raise ArgumentError, "Missing not_after argument" unless not_after
    unless key.kind_of?(OpenSSL::PKey::RSA)
      key = OpenSSL::PKey::RSA.new(key)
    end
    name = OpenSSL::X509::Name.parse("/C=US/ST=Illinois/O=#{organization}/CN=#{common_name}")
    cert = OpenSSL::X509::Certificate.new
    cert.version    = 2
    cert.serial     = 0
    cert.not_before = not_before
    cert.not_after  = not_after
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