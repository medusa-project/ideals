namespace :handles do

  desc 'Delete all IDEALS handles from the handle server'
  task :purge => :environment do
    HandleClient.new # TODO: write this
  end

  desc 'Create/update handles for all database entities'
  task :put_all => :environment do |task, args|
    Handle.all.each do |handle|
      handle.put_to_server
    end
  end

end
