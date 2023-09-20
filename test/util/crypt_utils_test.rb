require 'test_helper'

class CryptUtilsTest < ActiveSupport::TestCase

  # generate_cert()

  test "generate_cert() when given a string key returns a correct value" do
    key  = CryptUtils.generate_key
    cert = CryptUtils.generate_cert(key: key.private_to_pem,
                                    organization: "Acme Inc.",
                                    common_name:  "Cats")
    assert_equal "sha256WithRSAEncryption", cert.signature_algorithm
    assert cert.subject.to_s.include?("O=Acme Inc.")
    assert cert.subject.to_s.include?("CN=Cats")
  end

  test "generate_cert() when given an OpenSSL::PKey::RSA key returns a correct
  value" do
    key  = CryptUtils.generate_key
    cert = CryptUtils.generate_cert(key:          key,
                                    organization: "Acme Inc.",
                                    common_name:  "Cats")
    assert_equal "sha256WithRSAEncryption", cert.signature_algorithm
    assert cert.subject.to_s.include?("O=Acme Inc.")
    assert cert.subject.to_s.include?("CN=Cats")
  end

  # generate_key()

  test "generate_key() returns a correct value" do
    assert_kind_of OpenSSL::PKey::RSA, CryptUtils.generate_key
  end

end
