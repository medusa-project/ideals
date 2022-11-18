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

end
