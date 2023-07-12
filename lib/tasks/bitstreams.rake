require 'rake'

namespace :bitstreams do

  desc "Export all bitstreams attached to all items in a collection"
  task :export_collection, [:collection_id] => :environment do |task, args|
    collection = Collection.find(args[:collection_id])
    download   = Download.create!(institution: collection.institution,
                                  filename:    "collection-#{collection.id}-#{Time.now.to_i}.zip")
    Item.create_zip_file(item_ids:       collection.items.where(stage: Item::Stages::APPROVED).pluck(:id),
                         dest_key:       download.object_key,
                         print_progress: true)
    scheme = (Rails.env.development? || Rails.env.test?) ? "http" : "https"
    puts "File is ready at the following URL:\n\n#{scheme}://#{collection.institution.fqdn}/downloads/#{download.key}/file"
  end

  desc "Read the full text of bitstreams for which this has not been done yet"
  task :read_full_text, [:thread_count] => :environment do |task, args|
    num_threads = args[:thread_count].to_i
    num_threads = 1 if num_threads < 1

    bitstream_ids = Bitstream.
      where(full_text_checked_at: nil).
      where("(LOWER(filename) LIKE '%.pdf' OR LOWER(filename) LIKE '%.txt')").
      where("staging_key IS NOT NULL OR permanent_key IS NOT NULL").
      order(:id).
      pluck(:id)
    count = bitstream_ids.length
    puts "#{count} bitstreams for which full text has not yet been checked."
    puts "This command can be canceled and resumed without losing progress."

    ThreadUtils.process_in_parallel(bitstream_ids,
                                    num_threads: num_threads,
                                    print_progress: true) do |id|
      bs = Bitstream.find(id)
      bs.read_full_text
    end
  end

  desc "Ingest bitstreams into Medusa that have not already been ingested"
  task :ingest_into_medusa => :environment do |task, args|
    bitstreams = Bitstream.
      where(medusa_uuid: nil).
      where("permanent_key IS NOT NULL").
      reject(&:submitted_for_ingest?).
      reject{ |b| !b.item.handle }
    puts "#{bitstreams.count} bitstreams left to ingest"
    count    = bitstreams.count
    progress = Progress.new(count)

    Bitstream.uncached do
      bitstreams.each_with_index do |bs, index|
        begin
          bs.ingest_into_medusa
          progress.report(index, "Ingesting bitstreams into Medusa")
        rescue => e
          puts "#{e} [bitstream ID: #{bs.id}]"
        end
      end
    end
    puts ""
  end

  desc "Handle bitstreams for which ingest messages have been sent but no
    response messages have been received"
  task sync_with_medusa: :environment do
    config           = Configuration.instance
    file_group       = Medusa::FileGroup.with_id(config.medusa[:file_group_id])
    num_in_bucket    = 0
    num_in_medusa_db = 0
    num_updated      = 0
    num_reingests    = 0

    bitstreams = Bitstream.
      where(medusa_uuid: nil).
      select(&:submitted_for_ingest?)
    count      = bitstreams.count
    puts "#{count} bitstreams submitted for ingest but with unknown Medusa UUID..."
    bitstreams.each do |bs|
      target_key          = file_group.directory.relative_key + "/" +
        Bitstream.medusa_key(bs.item.handle.handle, bs.filename)
      exists_in_bucket    = PersistentStore.instance.object_exists?(key: target_key)
      num_in_bucket      += 1 if exists_in_bucket
      exists_in_medusa_db = false
      file_group.directory.walk_tree do |node|
        if node.relative_key == target_key
          exists_in_medusa_db = true
          if exists_in_bucket
            bs.update!(medusa_uuid: node.uuid,
                       medusa_key:  node.relative_key)
            bs.delete_from_staging
            num_updated += 1
          end
          break
        end
      end
      num_in_medusa_db += 1 if exists_in_medusa_db
      if !exists_in_medusa_db && exists_in_bucket
        bs.ingest_into_medusa
        num_reingests += 1
      elsif !exists_in_medusa_db && !exists_in_bucket
        puts "Bitstream #{bs.id} not present in Medusa database or bucket. Try re-ingesting."
      end
    end
    puts "# of bitstreams in Medusa bucket: #{num_in_bucket}"
    puts "# of bitstreams in Medusa DB:     #{num_in_medusa_db}"
    puts "# of bitstreams updated:          #{num_updated}"
    puts "# of ingest messages sent:        #{num_reingests}"
  end

end