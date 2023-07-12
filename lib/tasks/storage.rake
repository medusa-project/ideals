require "rake"

namespace :storage do

  desc "Purge all objects from the application storage bucket"
  task :purge => :environment do
    if Rails.env.demo? || Rails.env.production?
      puts "This can only be done in development or test."
      return
    end
    config = ::Configuration.instance
    S3Client.instance.delete_objects(bucket: config.storage[:bucket])
  end

end
