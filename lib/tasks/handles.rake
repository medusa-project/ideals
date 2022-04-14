namespace :handles do

  desc 'Delete all IDEALS handles from the handle server'
  task :purge => :environment do
    client   = HandleClient.new
    handles  = client.get_handles
    progress = Progress.new(handles.length)

    handles.each_with_index do |handle, index|
      client.delete_handle(handle)
      progress.report(index, "Purging handles")
    end
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
