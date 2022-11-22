require "rake"

namespace :storage do

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
        staging_bitstreams   = Bitstream.where("staging_key IS NOT NULL AND staging_key NOT LIKE ?",
                                               "institutions/%")
        permanent_bitstreams = Bitstream.where("permanent_key IS NOT NULL AND permanent_key NOT LIKE ?",
                                               "institutions/%")
        progress             = Progress.new(staging_bitstreams.count + permanent_bitstreams.count)
        i                    = 0
        staging_bitstreams.find_each do |bs|
          obj        = resource.bucket(bucket).object(bs.staging_key)
          target_key = "#{Bitstream::INSTITUTION_KEY_PREFIX}/uiuc/#{obj.key}"
          begin
            obj.move_to(bucket: bucket, key: target_key)
            bs.update!(staging_key: "#{Bitstream::INSTITUTION_KEY_PREFIX}/uiuc/#{bs.staging_key}")
          rescue Aws::S3::Errors::NoSuchKey
          rescue => e
            puts "#{obj.key}: #{e}"
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
          rescue => e
            puts "#{obj.key}: #{e}"
          end
          i += 1
          progress.report(i, "Reorganizing storage")
        end
      end
    end
  end

  # TODO: this can be removed after it has been done in all environments
  desc "Add institution tags to all objects"
  task :add_institution_tags => :environment do
    client   = S3Client.instance
    store    = PersistentStore.instance
    bucket   = ::Configuration.instance.storage[:bucket]
    count    = store.object_count(key_prefix: "institutions")
    progress = Progress.new(count)

    store.objects(key_prefix: "institutions").each_with_index do |obj, index|
      ins_key = obj.key.match(/^institutions\/(\w+)/i).captures[0]
      client.set_tag(bucket:    bucket,
                     key:       obj.key,
                     tag_key:   "institution_key",
                     tag_value: ins_key)
      progress.report(index, "Adding institution tags to bucket objects")
    end
  end

  # TODO: this can be removed once it has been done in demo and production
  desc "Make all bucket objects public"
  task make_all_objects_public: :environment do
    client   = S3Client.instance
    bucket   = ::Configuration.instance.storage[:bucket]
    count    = client.objects(bucket: bucket, key_prefix: "").count
    progress = Progress.new(count)
    client.objects(bucket: bucket, key_prefix: "").each_with_index do |obj, index|
      client.put_object_acl(
        acl:    "public-read",
        bucket: bucket,
        key:    obj.key
      )
      progress.report(index, "Updating object ACLs")
    end
  end

  desc "Purge all objects from the application storage bucket"
  task :purge => :environment do
    config = ::Configuration.instance
    S3Client.instance.delete_objects(bucket: config.storage[:bucket])
  end

end
