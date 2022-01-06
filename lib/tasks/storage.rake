namespace :storage do

  desc "Purge all objects from the application storage"
  task :purge => :environment do
    S3Client.instance.delete_objects(bucket: ::Configuration.instance.aws[:bucket])
  end

end
