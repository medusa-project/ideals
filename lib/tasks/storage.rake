require "rake"

namespace :storage do

  desc "Purge all objects from the application storage bucket"
  task :purge => :environment do
    config = ::Configuration.instance
    S3Client.instance.delete_objects(bucket: config.storage[:bucket])
  end

end
