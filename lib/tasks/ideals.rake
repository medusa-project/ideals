require 'rake'

namespace :ideals do

  namespace :cache do
    desc "Clear Rails cache (sessions, views, etc.)"
    task clear: :environment do
      Rails.cache.clear
    end
  end

  desc "Seed the database (AFTER MIGRATION)"
  task seed_database: :environment do
    IdealsSeeder.new.seed
  end

end
