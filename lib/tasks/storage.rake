require "rake"

namespace :storage do

  desc "Purge all objects from the application storage bucket"
  task :purge => :environment do
    config = ::Configuration.instance
    S3Client.instance.delete_objects(bucket: config.storage[:bucket])
  end

  # TODO: this can be removed after it has been done in all environments
  desc "One-time reorganization of the storage bucket to support multi-tenancy"
  task :reorganize => :environment do
    client = S3Client.instance
    config = ::Configuration.instance
    bucket = config.storage[:bucket]

    # We expect the bitstream count to be a little lower than the number of
    # objects in the bucket, but this is good enough as a rough estimate.
    progress = Progress.new(Bitstream.count)
    client.objects(bucket: bucket, key_prefix: "").each.with_index do |obj, index|
      unless obj.key.start_with?(Bitstream::INSTITUTION_KEY_PREFIX)
        target_key = "#{Bitstream::INSTITUTION_KEY_PREFIX}/uiuc/#{obj.key}"
        obj.move_to(bucket: bucket, key: target_key)
      end
      progress.report(index, "Reorganizing storage bucket")
    end

    Bitstream.uncached do
      staging_bitstreams   = Bitstream.where("staging_key IS NOT NULL AND staging_key NOT LIKE ?", "institutions/%")
      permanent_bitstreams = Bitstream.where("permanent_key IS NOT NULL AND permanent_key NOT LIKE ?", "institutions/%")
      progress             = Progress.new(staging_bitstreams.count + permanent_bitstreams.count)
      i                    = 0
      staging_bitstreams.find_each do |bs|
        bs.update!(staging_key: "#{Bitstream::INSTITUTION_KEY_PREFIX}/uiuc/#{bs.staging_key}")
        i += 1
        progress.report(i, "Updating database bitstreams")
      end
      permanent_bitstreams.find_each do |bs|
        bs.update!(permanent_key: "#{Bitstream::INSTITUTION_KEY_PREFIX}/uiuc/#{bs.permanent_key}")
        i += 1
        progress.report(i, "Updating database bitstreams")
      end
    end
  end

end
