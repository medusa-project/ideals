require 'rake'

namespace :collections do

  desc "Export all files in a collection as a zip file"
  task :export_files, [:collection_id, :dest_key] => :environment do |task, args|
    collection      = Collection.find(args[:collection_id])
    request_context = RequestContext.new(institution: collection.institution)
    collection_ids  = [collection.id] + collection.all_child_ids

    puts "Compiling a list of item IDs"
    item_ids = []
    relation = Item.search.filter(Item::IndexFields::COLLECTIONS, collection_ids)
    ItemPolicy::Scope.new(request_context, relation).resolve.each_id_in_batches do |result|
      item_ids << result[:id]
    end

    puts "Creating zip file"
    Item.create_zip_file(item_ids:         item_ids,
                         metadata_profile: collection.effective_metadata_profile,
                         dest_key:         dest_key,
                         include_csv_file: false,
                         request_context:  request_context,
                         print_progress:   true)
  end

  desc "Reindex all collections"
  task reindex: :environment do
    # N.B.: orphaned documents are not deleted.
    Collection.bulk_reindex
  end

end