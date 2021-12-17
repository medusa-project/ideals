require 'rake'

namespace :ideals do

  namespace :bitstreams do

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

  namespace :cache do
    desc "Clear Rails cache (sessions, views, etc.)"
    task clear: :environment do
      Rails.cache.clear
    end
  end

  namespace :items do
    desc "Delete expired embargoes"
    task delete_expired_embargoes: :environment do
      Embargo.where("expires_at < NOW()").delete_all
    end

    desc "Get a URL to download an item's bitstreams in a zip file"
    task :download, [:id] => :environment do |task, args|
      item   = Item.find(args[:id])
      client = MedusaDownloaderClient.new
      puts client.download_url(item: item)
    end

    desc "Import items from a SAF package"
    task :import, [:package_path, :mapfile_path, :collection_id] => :environment do |task, args|
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

  namespace :users do
    desc "Create a local-identity sysadmin user"
    task :create_local_sysadmin, [:email, :password] => :environment do |task, args|
      user = LocalUser.create_manually(email:    args[:email],
                                       password: args[:password])
      user.user_groups << UserGroup.sysadmin
      user.save!
    end

    desc "Create a Shibboleth identity sysadmin user"
    task :create_shib_sysadmin, [:netid] => :environment do |task, args|
      email = "#{args[:netid]}@illinois.edu"
      user  = ShibbolethUser.no_omniauth(email)
      user.ad_groups << UserGroup.sysadmin.ad_groups.first
      user.save!
    end

    desc 'Delete a user'
    task :delete, [:email] => :environment do |task, args|
      email = args[:email]
      ActiveRecord::Base.transaction do
        LocalIdentity.destroy_by(email: email)
        Invitee.destroy_by(email: email)
        User.destroy_by(email: email)
      end
    end
  end

  desc "Seed the database (AFTER MIGRATION)"
  task seed: :environment do
    IdealsSeeder.new.seed
  end

end
