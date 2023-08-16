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
    # Update the institutions that are federation members
    md_files = {}
    Institution.distinct(:sso_federation).pluck(:sso_federation).select(&:present?).each do |federation|
      md_files[federation] = Institution.fetch_saml_config_metadata(federation: federation)
    end
    Institution.where.not(sso_federation: nil).each do |institution|
      institution.update_from_saml_config_metadata(md_files[institution.sso_federation])
    end
    md_files.each(&:unlink)

    # Update the institutions that are not federation members
    Institution.where.not(saml_config_metadata_url: nil).each do |institution|
      md_file = Institution.fetch_saml_config_metadata(url: institution.saml_config_metadata_url)
      institution.update_from_saml_config_metadata(md_file)
    end
  end

end
