require 'rake'

namespace :items do

  desc "Delete expired embargoes"
  task delete_expired_embargoes: :environment do
    Embargo.where("expires_at < NOW()").delete_all
  end


  desc "Import items from a SAF package"
  task :import_saf, [:package_path, :mapfile_path, :collection_id] => :environment do |task, args|
    # Argument validation and setup.
    collection   = Collection.find(args[:collection_id])
    package_path = File.expand_path(args[:package_path])
    mapfile_path = File.expand_path(args[:mapfile_path])
    puts package_path
    # Do the import.
    SafImporter.new.import_from_path(pathname:           package_path,
                                     primary_collection: collection,
                                     mapfile_path:       mapfile_path,
                                     print_progress:     true)
    puts "Import succeeded."
  end
  desc "Import items from a SAF package"
  task :batch_assign_embargo, [ :mapfile_path, :embargo_json] => :environment do |task, args|
    if File.exist?(args[:embargo_json])
      embargo=JSON.parse(File.read(args[:embargo_json]))
    end
    puts embargo

    expires_at_year=embargo["expires_at"].split("-")[0]
    expires_at_month=embargo["expires_at"].split("-")[1]
    expires_at_day=embargo["expires_at"].split("-")[2]



    # kind:           embargo[:kind].to_i,
    #   user_group_ids: embargo[:user_group_ids]&.uniq,
    #   reason:         embargo[:reason],
    #   perpetual:      embargo[:perpetual] == "true",
    #   expires_at:     TimeUtils.ymd_to_time(embargo[:expires_at_year],
    #                                         embargo[:expires_at_month],
    #                                         embargo[:expires_at_day]))
    if File.exist?(args[:mapfile_path])
      item_handles = File.read(args[:mapfile_path]).
        split("\n").
        map{ |line| line.split("\t")[1] }.
        select(&:present?)
    else
      raise "mapfile does not exist"
    end
    suffix_list=item_handles.map do |handle| handle.split("/")[1] end
    handle_obj_arr=Handle.where("suffix in (?)", suffix_list)
    handle_obj_arr.each do |handle_obj|
      item=Item.find(handle_obj.item_id)

      item.embargoes.build(
        kind:           embargo["kind"].to_i,
        user_group_ids: embargo["user_group_ids"],
        reason:         embargo["reason"],
        perpetual:      embargo["perpetual"] == "true",
        expires_at:     TimeUtils.ymd_to_time(expires_at_year, expires_at_month, expires_at_day)
      )
      item.save!
    end
  end

  desc "Reindex all items"
  task :reindex, [:num_threads] => :environment do |task, args|
    # N.B.: orphaned documents are not deleted.
    num_threads = args[:num_threads].to_i
    num_threads = 1 if num_threads == 0
    Item.reindex_all(num_threads: num_threads)
  end

end