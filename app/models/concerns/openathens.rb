##
# Included by {Institution}.
#
module Openathens
  extend ActiveSupport::Concern

  OPENATHENS_METADATA_URL = "http://fed.openathens.net/oafed/metadata"
  SAML_METADATA_NS        = "urn:oasis:names:tc:SAML:2.0:metadata"
  XML_DS_NS               = "http://www.w3.org/2000/09/xmldsig#"

  class_methods do

    ##
    # @return [File] OpenAthens metadata XML file.
    #
    def fetch_openathens_metadata
      uri  = URI.parse(OPENATHENS_METADATA_URL)
      file = Tempfile.new("oaf_metadata")
      begin
        file.binmode
        Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Get.new(uri)
          http.request(request) do |response|
            response.read_body do |chunk|
              file.write(chunk)
            end
            file.close
          end
        end
        return file
      rescue => e
        file.unlink
        raise e
      end
    end

  end

  included do

    ##
    # @param metadata_xml_file [File]
    #
    def update_from_openathens(metadata_xml_file)
      if self.saml_idp_entity_id.blank?
        raise "saml_idp_entity_id is not set"
      end
      File.open(metadata_xml_file) do |file|
        doc = Nokogiri::XML(file)
        results = doc.xpath("/md:EntitiesDescriptor/md:EntityDescriptor[@entityID = '#{self.saml_idp_entity_id}']",
                            md: SAML_METADATA_NS)
        if results.any?
          ed = results.first
          self.saml_idp_sso_service_url = ed.xpath("./md:IDPSSODescriptor/md:SingleSignOnService[@Binding = 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect']/@Location",
                                                   md: SAML_METADATA_NS).first&.text
          self.saml_idp_cert = "-----BEGIN CERTIFICATE-----\n" +
            ed.xpath("//ds:X509Certificate", ds: XML_DS_NS).first.text +
            "\n-----END CERTIFICATE-----"
          self.save!
        else
          raise "No matching entityID found in OpenAthens Federation metadata"
        end
      end
    end

  end

end
