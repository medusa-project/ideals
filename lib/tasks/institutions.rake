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
    md_files = {}
    Institution.distinct(:sso_federation).pluck(:sso_federation).select(&:present?).each do |federation|
      md_files[federation] = Institution.fetch_federation_metadata(federation)
    end

    Institution.where.not(sso_federation: nil).each do |institution|
      institution.update_from_federation_metadata(md_files[institution.sso_federation])
    end
    md_files.each(&:unlink)
  end

end
