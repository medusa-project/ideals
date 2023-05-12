namespace :institutions do

  desc "Regenerate favicons"
  task :regenerate_favicons => :environment do
    Institution.all.each do |institution|
      begin
        institution.regenerate_favicons
      rescue => e
        puts "Institution #{institution.key}: #{e}"
      end
    end
  end

  desc "Update the auth metadata of all institutions"
  task :update_auth_metadata => :environment do
    # OpenAthens Federation
    xml_file = Institution.fetch_openathens_metadata
    begin
      Institution.where(sso_federation: Institution::SSOFederation::OPENATHENS).each do |institution|
        institution.update_from_openathens(xml_file)
      end
    ensure
      xml_file.unlink
    end

    # Other federations go here
  end

end
