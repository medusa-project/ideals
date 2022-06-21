namespace :handles do

  desc 'List all prefixes on the handle server'
  task :list_prefixes => :environment do
    puts HandleClient.new.list_prefixes
  end

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
    Handle.uncached do
      handles  = Handle.all.order(:id)
      count    = handles.count
      progress = Progress.new(count)
      handles.find_each.with_index do |handle, index|
        handle.put_to_server
        progress.report(index, "Uploading handles")
      end
    end
  end

end
