require 'rake'

##
# These tasks relate to migrating data out of IDEALS-DSpace. After the
# migration is complete, they can be removed.
#
namespace :ideals_dspace do

  namespace :bitstreams do

    IDEALS_DSPACE_HOSTNAME         = "ideals.illinois.edu"
    IDEALS_DSPACE_ASSET_STORE_PATH = "/services/ideals-dspace/data/dspace/assetstore"

    ##
    # Do this AFTER database content has been migrated.
    #
    desc "Copy IDEALS-DSpace bitstreams into Medusa"
    task :copy_into_medusa, [:ideals_dspace_ssh_user] => :environment do |task, args|
      Net::SCP.start(IDEALS_DSPACE_HOSTNAME, args[:ideals_dspace_ssh_user]) do |scp|
        Dir.mktmpdir do |tmpdir|
          puts "Temp directory: #{tmpdir}"
          Bitstream.uncached do
            bitstreams      = Bitstream.where.not(dspace_id: [nil, ""]).order(:id)
            bitstream_count = bitstreams.count
            progress        = Progress.new(bitstream_count)
            bitstreams.each_with_index do |bitstream, index|
              # Download the file into the temp directory
              remote_path = IDEALS_DSPACE_ASSET_STORE_PATH +
                  bitstream.dspace_relative_path
              local_path  = File.join(tmpdir, "#{bitstream.id}")
              scp.download!(remote_path, local_path)
              # Upload it to the application S3 bucket under the staging area
              bitstream.update!(staging_key: Bitstream.staging_key(bitstream.item.id,
                                                                   bitstream.original_filename))
              bitstream.upload_to_staging(File.read(local_path))
              # Delete it from the temp directory
              File.delete(local_path)
              # Tell Medusa to ingest it
              bitstream.ingest_into_medusa
              progress.report(index, "Transferring files from IDEALS-DSpace into Medusa")
            end
          end
        end
      end
    end

    desc "Migrate bitstreams from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name,
                    :source_db_host,
                    :source_db_user,
                    :source_db_password] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_bitstreams.sql",
                 :import_bitstreams)
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_bitstream_bundles.sql",
                 :import_bitstream_bundles)
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_bitstream_metadata.sql",
                 :import_bitstream_metadata)
    end
  end

  namespace :collections do
    desc "Migrate collections from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name,
                    :source_db_host,
                    :source_db_user,
                    :source_db_password] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_collections.sql",
                 :import_collections)
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_collections_2_communities.sql",
                 :import_collections_2_communities)
    end
  end

  namespace :communities do
    desc "Migrate communities from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name,
                    :source_db_host,
                    :source_db_user,
                    :source_db_password] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_communities.sql",
                 :import_communities)
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_communities_2_communities.sql",
                 :import_communities_2_communities)
    end
  end

  namespace :handles do
    desc "Migrate handles from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name,
                    :source_db_host,
                    :source_db_user,
                    :source_db_password] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_handles.sql",
                 :import_handles)
    end
  end

  namespace :items do
    desc "Migrate items from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name,
                    :source_db_host,
                    :source_db_user,
                    :source_db_password] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_items.sql",
                 :import_items)
    end
  end

  namespace :metadata do
    desc "Migrate metadata registry from IDEALS-DSpace into the application"
    task :migrate_registry, [:source_db_name,
                             :source_db_host,
                             :source_db_user,
                             :source_db_password] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_metadata_registry.sql",
                 :import_metadata_registry)
    end

    desc "Migrate collection metadata from IDEALS-DSpace into the application"
    task :migrate_collection_values, [:source_db_name,
                                      :source_db_host,
                                      :source_db_user,
                                      :source_db_password] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_collection_metadata.sql",
                 :import_collection_metadata)
    end

    desc "Migrate item metadata from IDEALS-DSpace into the application"
    task :migrate_item_values, [:source_db_name,
                                :source_db_host,
                                :source_db_user,
                                :source_db_password] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_item_metadata.sql",
                 :import_item_metadata)
    end
  end

  namespace :users do
    desc "Migrate users from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name,
                    :source_db_host,
                    :source_db_user,
                    :source_db_password] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_users_1.sql",
                 :import_users)
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_users_2.sql",
                 :import_users)
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_user_metadata.sql",
                 :import_user_metadata)
    end
  end

  desc "Migrate all content from IDEALS-DSpace into the application"
  task :migrate, [:source_db_name,
                  :source_db_host,
                  :source_db_user,
                  :source_db_password] => :environment do |task, args|
    dbname = args[:source_db_name]
    dbhost = args[:source_db_host]
    dbuser = args[:source_db_user]
    dbpass = args[:source_db_password]
    Rake::Task["ideals_dspace:metadata:migrate_registry"].invoke(dbname, dbhost, dbuser, dbpass)
    Rake::Task["ideals_dspace:users:migrate"].invoke(dbname, dbhost, dbuser, dbpass)
    Rake::Task["ideals_dspace:communities:migrate"].invoke(dbname, dbhost, dbuser, dbpass)
    Rake::Task["ideals_dspace:collections:migrate"].invoke(dbname, dbhost, dbuser, dbpass)
    Rake::Task["ideals_dspace:items:migrate"].invoke(dbname, dbhost, dbuser, dbpass)
    Rake::Task["ideals_dspace:bitstreams:migrate"].invoke(dbname, dbhost, dbuser, dbpass)
    Rake::Task["ideals_dspace:handles:migrate"].invoke(dbname, dbhost, dbuser, dbpass)
    Rake::Task["ideals_dspace:metadata:migrate_collection_values"].invoke(dbname, dbhost, dbuser, dbpass)
    puts "WARNING: This is the last step, but it takes a long time. "\
        "You can ctrl+c at any time if you don't need full item metadata."
    Rake::Task["ideals_dspace:metadata:migrate_item_values"].invoke(dbname, dbhost, dbuser, dbpass)
  end

  def do_migrate(source_db_name, source_db_host, source_db_user,
                 source_db_password, in_sql_file, import_method)
    out_csv_file = in_sql_file.gsub(/.sql$/i, ".csv")
    in_sql_file = File.join(Rails.root, "scripts", in_sql_file)
    Dir.mktmpdir do |dir|
      out_csv_file = File.join(dir, out_csv_file)
      if source_db_host.present?
        cmd = ""
        cmd += "export PGPASSWORD='#{source_db_password}'; " if source_db_password.present?
        cmd += "psql -h %s -U %s -d %s -f '%s' > '%s'"
        system sprintf(cmd,
                       source_db_host, source_db_user, source_db_name,
                       in_sql_file, out_csv_file)
      else
        cmd = ""
        cmd += "export PGPASSWORD='#{source_db_password}'; " if source_db_password.present?
        cmd += "psql -d %s -f '%s' > '%s'"
        system sprintf(cmd, source_db_name, in_sql_file, out_csv_file)
      end
      IdealsImporter.instance.send(import_method, out_csv_file)
    end
  end

end
