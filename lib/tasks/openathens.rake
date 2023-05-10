namespace :openathens do

  desc "Update the metadata of all OpenAthens institutions"
  task :update_metadata => :environment do
    xml_file = Institution.fetch_openathens_metadata
    begin
      Institution.where.(sso_federation: Institution::SamlFederation::OPENATHENS).each do |institution|
        institution.update_from_openathens(xml_file)
      end
    ensure
      xml_file.unlink
    end
  end

end
