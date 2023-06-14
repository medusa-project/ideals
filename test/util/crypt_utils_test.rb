require 'test_helper'

class CryptUtilsTest < ActiveSupport::TestCase

  test "generate_x509_pem_pair() returns correct values" do
    result       = CryptUtils.generate_cert_pair(organization: "Acme Inc.",
                                                 common_name:  "Cats")
    public_cert  = OpenSSL::X509::Certificate.new(result[:public])
    assert_equal "sha256WithRSAEncryption", public_cert.signature_algorithm
    private_cert = OpenSSL::PKey::RSA.new(result[:private])
  end

end
