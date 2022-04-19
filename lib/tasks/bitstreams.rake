require 'rake'

namespace :bitstreams do

  desc "Read the full text of bitstreams for which this has not been done yet"
  task :read_full_text, [:thread_count] => :environment do |task, args|
    num_threads = args[:thread_count].to_i
    num_threads = 1 if num_threads < 1

    bitstreams = Bitstream.
      where(full_text_checked_at: nil).
      where("staging_key IS NOT NULL OR permanent_key IS NOT NULL").
      order(:id)
    count = bitstreams.count
    puts "#{count} bitstreams for which full text has not yet been checked."
    puts "This command can be canceled and resumed without losing progress."

    ThreadUtils.process_in_parallel(bitstreams,
                                    num_threads: num_threads,
                                    print_progress: true) do |bs|
      bs.read_full_text
    end
  end

  desc "Handle bitstreams for which ingest messages have been sent but no
    response messages have been received"
  task sync_with_medusa: :environment do
    config           = Configuration.instance
    file_group       = Medusa::FileGroup.with_id(config.medusa[:file_group_id])
    target_bucket    = config.medusa[:bucket]
    num_in_bucket    = 0
    num_in_medusa_db = 0
    num_updated      = 0
    num_reingests    = 0

    bitstreams = Bitstream.where(submitted_for_ingest: true, medusa_uuid: nil)
    count      = bitstreams.count
    puts "#{count} bitstreams submitted for ingest but with unknown Medusa UUID..."
    bitstreams.each do |bs|
      target_key = file_group.directory.relative_key + "/" +
        Bitstream.medusa_key(bs.item.handle.handle,
                             bs.original_filename)

      exists_in_bucket = S3Client.instance.object_exists?(bucket: target_bucket,
                                                          key:    target_key)
      num_in_bucket += 1 if exists_in_bucket

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
        bs.ingest_into_medusa(force: true)
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