require 'rake'

namespace :ideals do

  namespace :cache do
    desc "Clear Rails cache (sessions, views, etc.)"
    task clear: :environment do
      Rails.cache.clear
    end
  end

  desc "Purge all objects from the application storage"
  task :purge_bucket => :environment do
    config = ::Configuration.instance
    S3Client.instance.delete_objects(bucket: config.storage[:bucket])
  end

  desc "Seed the database (AFTER MIGRATION)"
  task seed_database: :environment do
    IdealsSeeder.new.seed
  end

end
