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
    # Do the import.
    SafImporter.new.import_from_path(pathname:           package_path,
                                     primary_collection: collection,
                                     mapfile_path:       mapfile_path,
                                     print_progress:     true)
    puts "Import succeeded."
  end

end