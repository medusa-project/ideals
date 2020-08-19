namespace :handles do

  desc 'Delete all IDEALS handles from the handle server'
  task :purge => :environment do
    HandleClient.new # TODO: write this
  end

  desc 'Create/update handles for all database entities'
  task :put_all => :environment do |task, args|
    count = Handle.count
    progress = Progress.new(count)
    Handle.all.each_with_index do |handle, i|
      handle.put_to_server
      progress.report(i, "Uploading handles")
    end
  end

end
