# frozen_string_literal: true

class CryptUtils

  ##
  # Generates a private key in PKCS#8 format along with a public X.509
  # certificate. (If desired, these could be saved as `.pem` files.)
  #
  # @param organization [String]
  # @param common_name [String]
  # @param expires_in [Integer] Expiration in seconds from now.
  # @return [Hash<Symbol,String>] Hash with `:public` and `:private` keys.
  #
  def self.generate_cert_pair(organization:,
                              common_name:,
                              expires_in: 10.years.to_i)
    key  = OpenSSL::PKey::RSA.new(4096)
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
    {
      public:  cert.to_pem,
      private: key.private_to_pem # PKCS#8 format (to_pem() returns RSA format)
    }
  end

end