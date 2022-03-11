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
    # This is resumable--if stopped and run again, it will pick up where it
    # left off.
    #
    desc "Copy all IDEALS-DSpace bitstreams into IDEALS"
    task :copy, [:ideals_dspace_ssh_user, :num_threads] => :environment do |task, args|
      num_threads = args[:num_threads].to_i
      Dir.mktmpdir do |tmpdir|
        Bitstream.uncached do
          bitstreams = Bitstream.
            where(permanent_key: [nil, ""]).
            where.not(dspace_id: [nil, ""]).
            order(:length)
          puts "#{bitstreams.count} bitstreams to copy"
          puts "Temp directory: #{tmpdir}"
          ThreadUtils.process_in_parallel(bitstreams,
                                          num_threads:    num_threads,
                                          print_progress: true) do |bitstream|
            # Download the file into the temp directory
            remote_path = IDEALS_DSPACE_ASSET_STORE_PATH +
              bitstream.dspace_relative_path
            local_path  = File.join(tmpdir, "#{bitstream.id}")

            `scp #{args[:ideals_dspace_ssh_user]}@#{IDEALS_DSPACE_HOSTNAME}:#{remote_path} #{local_path}`

            # Upload it to the application S3 bucket
            bitstream.permanent_key = Bitstream.permanent_key(bitstream.item.id,
                                                              bitstream.original_filename)
            bitstream.upload_to_permanent(local_path)
            begin
              bitstream.save!
            rescue => e
              puts "#{e} (bitstream ID; #{bitstream.id})"
              puts e.backtrace
            end
            # Delete it from the temp directory
            File.delete(local_path)
          end
        end
      end
    end

    desc "Copy one collection's bitstreams from IDEALS-DSpace into IDEALS"
    task :copy_collection, [:collection_id, :ideals_dspace_ssh_user] => :environment do |task, args|
      Net::SCP.start(IDEALS_DSPACE_HOSTNAME, args[:ideals_dspace_ssh_user]) do |scp|
        Dir.mktmpdir do |tmpdir|
          puts "Temp directory: #{tmpdir}"
          bitstreams      = Bitstream.joins("LEFT JOIN collection_item_memberships m ON m.item_id = bitstreams.item_id").
            where("m.collection_id": args[:collection_id]).
            where(permanent_key: [nil, ""]).
            where.not(dspace_id: [nil, ""]).
            order(:length)
          bitstream_count = bitstreams.count
          progress        = Progress.new(bitstream_count)
          bitstreams.find_each.with_index do |bitstream, index|
            # Download the file into the temp directory
            remote_path = IDEALS_DSPACE_ASSET_STORE_PATH +
              bitstream.dspace_relative_path
            local_path  = File.join(tmpdir, "#{bitstream.id}")
            scp.download!(remote_path, local_path)
            # Upload it to the application S3 bucket
            bitstream.permanent_key = Bitstream.permanent_key(bitstream.item.id,
                                                              bitstream.original_filename)
            bitstream.upload_to_permanent(local_path)
            bitstream.save!
            # Delete it from the temp directory
            File.delete(local_path)
            progress.report(index, "Copying files from IDEALS-DSpace into Medusa")
          end
        end
      end
    end

    desc "Copy one item's bitstreams from IDEALS-DSpace into IDEALS"
    task :copy_item, [:item_id, :ideals_dspace_ssh_user] => :environment do |task, args|
      Net::SCP.start(IDEALS_DSPACE_HOSTNAME, args[:ideals_dspace_ssh_user]) do |scp|
        Dir.mktmpdir do |tmpdir|
          puts "Temp directory: #{tmpdir}"
          item            = Item.find(args[:item_id])
          bitstreams      = item.bitstreams.where.not(dspace_id: [nil, ""])
          bitstream_count = bitstreams.count
          progress        = Progress.new(bitstream_count)
          bitstreams.each_with_index do |bitstream, index|
            # Download the file into the temp directory
            remote_path = IDEALS_DSPACE_ASSET_STORE_PATH +
              bitstream.dspace_relative_path
            local_path  = File.join(tmpdir, "#{bitstream.id}")
            scp.download!(remote_path, local_path)
            # Upload it to the application S3 bucket
            bitstream.permanent_key = Bitstream.permanent_key(bitstream.item.id,
                                                              bitstream.original_filename)
            bitstream.upload_to_permanent(local_path)
            bitstream.save!
            # Delete it from the temp directory
            File.delete(local_path)
            progress.report(index, "Copying files from IDEALS-DSpace into Medusa")
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

    desc "Incrementally migrate bitstreams from IDEALS-DSpace into the application"
    task :migrate_incremental, [:source_db_name,
                                :source_db_host,
                                :source_db_user,
                                :source_db_password] => :environment do |task, args|
      joined_ids = Bitstream.pluck(:id).join(", ")
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "incremental/export_bitstreams.sql",
                 :import_bitstreams,
                 joined_ids)
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "incremental/export_bitstream_bundles.sql",
                 :import_bitstream_bundles,
                 joined_ids)
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "incremental/export_bitstream_metadata.sql",
                 :import_bitstream_metadata,
                 joined_ids)
    end

    desc "Migrate bitstream statistics from IDEALS-DSpace into the application"
    task :migrate_statistics, [:source_db_name,
                               :source_db_host,
                               :source_db_user,
                               :source_db_password] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_bitstream_statistics.sql",
                 :import_bitstream_statistics)
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

    desc "Incrementally migrate collections from IDEALS-DSpace into the application"
    task :migrate_incremental, [:source_db_name,
                                :source_db_host,
                                :source_db_user,
                                :source_db_password] => :environment do |task, args|
      joined_ids = Collection.pluck(:id).join(",")
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "incremental/export_collections.sql",
                 :import_collections,
                 joined_ids)
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

    desc "Incrementally migrate communities from IDEALS-DSpace into the application"
    task :migrate_incremental, [:source_db_name,
                                :source_db_host,
                                :source_db_user,
                                :source_db_password] => :environment do |task, args|
      joined_ids = Unit.pluck(:id).join(",")
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "incremental/export_communities.sql",
                 :import_communities,
                 joined_ids)
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

    desc "Incrementally migrate handles from IDEALS-DSpace into the application"
    task :migrate_incremental, [:source_db_name,
                                :source_db_host,
                                :source_db_user,
                                :source_db_password] => :environment do |task, args|
      joined_ids = Handle.pluck(:suffix).
        map{ |suffix| "'#{::Configuration.instance.handles[:prefix]}/#{suffix}'" }.
        join(",")
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "incremental/export_handles.sql",
                 :import_handles,
                 joined_ids)
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
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_collections_2_items.sql",
                 :import_collections_2_items)
    end

    desc "Incrementally migrate items from IDEALS-DSpace into the application"
    task :migrate_incremental, [:source_db_name,
                                :source_db_host,
                                :source_db_user,
                                :source_db_password] => :environment do |task, args|
      joined_ids = Item.pluck(:id).join(",")
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "incremental/export_items.sql",
                 :import_items,
                 joined_ids)
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_collections_2_items.sql",
                 :import_collections_2_items)
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

    desc "Incrementally migrate metadata registry from IDEALS-DSpace into the application"
    task :migrate_registry_incremental, [:source_db_name,
                                         :source_db_host,
                                         :source_db_user,
                                         :source_db_password] => :environment do |task, args|
      joined_ids = RegisteredElement.pluck(:id).join(",")
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "incremental/export_metadata_registry.sql",
                 :import_metadata_registry,
                 joined_ids)
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
      IdealsImporter.instance.process_embargoes
    end

    desc "Incrementally migrate item metadata from IDEALS-DSpace into the application"
    task :migrate_item_values_incremental, [:source_db_name,
                                            :source_db_host,
                                            :source_db_user,
                                            :source_db_password] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "incremental/export_item_metadata.sql",
                 :import_item_metadata,
                 nil,
                 Time.now)
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
                 "export_users.sql",
                 :import_users)
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "export_user_metadata.sql",
                 :import_user_metadata)
    end

    desc "Incrementally migrate users from IDEALS-DSpace into the application"
    task :migrate_incremental, [:source_db_name,
                                :source_db_host,
                                :source_db_user,
                                :source_db_password] => :environment do |task, args|
      joined_ids = User.pluck(:id).join(",")
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "incremental/export_users.sql",
                 :import_users,
                 joined_ids)
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 args[:source_db_password],
                 "incremental/export_user_metadata.sql",
                 :import_user_metadata,
                 User.pluck(:id).join(","))
    end
  end

  desc "Migrate critical content from IDEALS-DSpace into the application"
  task :migrate_critical, [:source_db_name,
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
    puts "WARNING: This is the last step, but it takes a long time. "\
        "You can ctrl+c if you don't need full item metadata."
    Rake::Task["ideals_dspace:metadata:migrate_item_values"].invoke(dbname, dbhost, dbuser, dbpass)
  end

  desc "Migrate recently added critical content from IDEALS-DSpace into the application"
  task :migrate_incremental, [:source_db_name,
                              :source_db_host,
                              :source_db_user,
                              :source_db_password] => :environment do |task, args|
    dbname = args[:source_db_name]
    dbhost = args[:source_db_host]
    dbuser = args[:source_db_user]
    dbpass = args[:source_db_password]
    Rake::Task["ideals_dspace:metadata:migrate_registry_incremental"].invoke(dbname, dbhost, dbuser, dbpass)
    Rake::Task["ideals_dspace:users:migrate_incremental"].invoke(dbname, dbhost, dbuser, dbpass)
    Rake::Task["ideals_dspace:communities:migrate_incremental"].invoke(dbname, dbhost, dbuser, dbpass)
    Rake::Task["ideals_dspace:collections:migrate_incremental"].invoke(dbname, dbhost, dbuser, dbpass)
    Rake::Task["ideals_dspace:items:migrate_incremental"].invoke(dbname, dbhost, dbuser, dbpass)
    Rake::Task["ideals_dspace:bitstreams:migrate_incremental"].invoke(dbname, dbhost, dbuser, dbpass)
    Rake::Task["ideals_dspace:handles:migrate_incremental"].invoke(dbname, dbhost, dbuser, dbpass)
    Rake::Task["ideals_dspace:metadata:migrate_item_values_incremental"].invoke(dbname, dbhost, dbuser, dbpass)
  end

  desc "Migrate non-critical content from IDEALS-DSpace into the application"
  task :migrate_non_critical, [:source_db_name,
                               :source_db_host,
                               :source_db_user,
                               :source_db_password] => :environment do |task, args|
    dbname = args[:source_db_name]
    dbhost = args[:source_db_host]
    dbuser = args[:source_db_user]
    dbpass = args[:source_db_password]
    Rake::Task["ideals_dspace:bitstreams:migrate_statistics"].invoke(dbname, dbhost, dbuser, dbpass)
  end

  def do_migrate(source_db_name, source_db_host, source_db_user,
                 source_db_password, in_sql_file, import_method,
                 replace_ids = nil, replace_cutoff_date = nil)
    tempfile = nil
    begin
      out_csv_file = in_sql_file.gsub(/.sql$/i, ".csv")
      in_sql_file  = File.join(Rails.root, "scripts", in_sql_file)
      if replace_ids.present?
        tempfile = Tempfile.new("import")
        sql      = File.read(in_sql_file)
        sql.gsub!("####", replace_ids)
        tempfile.write(sql)
        tempfile.close
        in_sql_file = tempfile.path
      elsif replace_cutoff_date.present?
        tempfile = Tempfile.new("import")
        sql      = File.read(in_sql_file)
        sql.gsub!("$$$$", replace_cutoff_date.strftime("%Y-%m-%d"))
        tempfile.write(sql)
        tempfile.close
        in_sql_file = tempfile.path
      end
      Dir.mktmpdir do |dir|
        out_csv_file = File.join(dir, out_csv_file)
        FileUtils.mkdir_p(File.dirname(out_csv_file))
        if source_db_host.present?
          cmd = ""
          cmd += "export PGPASSWORD='#{source_db_password}'; " if source_db_password.present?
          cmd += "psql -h %s -U %s -d %s -f '%s' > '%s'"
          cmd = sprintf(cmd,
                        source_db_host, source_db_user, source_db_name,
                        in_sql_file, out_csv_file)
          puts "ERROR: #{cmd}" unless system(cmd)
        else
          cmd = ""
          cmd += "export PGPASSWORD='#{source_db_password}'; " if source_db_password.present?
          cmd += "psql -d %s -f '%s' > '%s'"
          cmd = sprintf(cmd, source_db_name, in_sql_file, out_csv_file)
          puts "ERROR: #{cmd}" unless system(cmd)
        end
        IdealsImporter.instance.send(import_method, out_csv_file)
      end
    ensure
      tempfile&.unlink
    end
  end

end
