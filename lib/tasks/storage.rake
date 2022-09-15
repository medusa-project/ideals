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
    config   = ::Configuration.instance
    bucket   = config.storage[:bucket]
    resource = Aws::S3::Resource.new(client: S3Client.instance)

    # We expect this to take several hours, so we do it twice, first to process
    # the vast majority, and then to process the possible few that have snuck
    # in since the first run.
    2.times do
      Bitstream.uncached do
        staging_bitstreams   = Bitstream.where("staging_key IS NOT NULL AND staging_key NOT LIKE ?", "institutions/%")
        permanent_bitstreams = Bitstream.where("permanent_key IS NOT NULL AND permanent_key NOT LIKE ?", "institutions/%")
        progress             = Progress.new(staging_bitstreams.count + permanent_bitstreams.count)
        i                    = 0
        staging_bitstreams.find_each do |bs|
          obj        = resource.bucket(bucket).object(bs.staging_key)
          target_key = "#{Bitstream::INSTITUTION_KEY_PREFIX}/uiuc/#{obj.key}"
          begin
            obj.move_to(bucket: bucket, key: target_key)
            bs.update!(staging_key: "#{Bitstream::INSTITUTION_KEY_PREFIX}/uiuc/#{bs.staging_key}")
          rescue Aws::S3::Errors::NoSuchKey
          end
          i += 1
          progress.report(i, "Reorganizing storage")
        end
        permanent_bitstreams.find_each do |bs|
          obj        = resource.bucket(bucket).object(bs.permanent_key)
          target_key = "#{Bitstream::INSTITUTION_KEY_PREFIX}/uiuc/#{obj.key}"
          begin
            obj.move_to(bucket: bucket, key: target_key)
            bs.update!(permanent_key: "#{Bitstream::INSTITUTION_KEY_PREFIX}/uiuc/#{bs.permanent_key}")
          rescue Aws::S3::Errors::NoSuchKey
          end
          i += 1
          progress.report(i, "Reorganizing storage")
        end
      end
    end
  end

end
