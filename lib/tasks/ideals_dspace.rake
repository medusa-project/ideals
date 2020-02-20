require 'rake'

namespace :ideals_dspace do

  namespace :collections do
    desc "Migrate collections from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name, :source_db_host, :source_db_user] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 "export_collections.sql",
                 :import_collections)
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 "export_collections_2_communities.sql",
                 :import_collections_2_communities)
    end
  end

  namespace :communities do
    desc "Migrate communities from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name, :source_db_host, :source_db_user] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 "export_communities.sql",
                 :import_communities)
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 "export_communities_2_communities.sql",
                 :import_communities_2_communities)
    end
  end

  namespace :handles do
    desc "Migrate handles from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name, :source_db_host, :source_db_user] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 "export_handles.sql",
                 :import_handles)
    end
  end

  namespace :items do
    desc "Migrate items from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name, :source_db_host, :source_db_user] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 "export_items.sql",
                 :import_items)
    end
  end

  namespace :metadata do
    desc "Migrate metadata registry from IDEALS-DSpace into the application"
    task :migrate_registry, [:source_db_name, :source_db_host, :source_db_user] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 "export_metadata_registry.sql",
                 :import_metadata_registry)
    end

    desc "Migrate collection metadata from IDEALS-DSpace into the application"
    task :migrate_collection_values, [:source_db_name, :source_db_host, :source_db_user] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 "export_collection_metadata.sql",
                 :import_collection_metadata)
    end

    desc "Migrate item metadata from IDEALS-DSpace into the application"
    task :migrate_item_values, [:source_db_name, :source_db_host, :source_db_user] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 "export_item_metadata.sql",
                 :import_item_metadata)
    end
  end

  namespace :users do
    desc "Migrate users from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name, :source_db_host, :source_db_user] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 "export_users_1.sql",
                 :import_users)
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 "export_users_2.sql",
                 :import_users)
      do_migrate(args[:source_db_name],
                 args[:source_db_host],
                 args[:source_db_user],
                 "export_user_metadata.sql",
                 :import_user_metadata)
    end
  end

  desc "Migrate all content from IDEALS-DSpace into the application"
  task :migrate, [:source_db_name, :source_db_host, :source_db_user] => :environment do |task, args|
    dbname = args[:source_db_name]
    dbhost = args[:source_db_host]
    dbuser = args[:source_db_user]
    Rake::Task["ideals_dspace:users:migrate"].invoke(dbname, dbhost, dbuser)
    Rake::Task["ideals_dspace:communities:migrate"].invoke(dbname, dbhost, dbuser)
    Rake::Task["ideals_dspace:collections:migrate"].invoke(dbname, dbhost, dbuser)
    Rake::Task["ideals_dspace:items:migrate"].invoke(dbname, dbhost, dbuser)
    Rake::Task["ideals_dspace:handles:migrate"].invoke(dbname, dbhost, dbuser)
    Rake::Task["ideals_dspace:metadata:migrate_registry"].invoke(dbname, dbhost, dbuser)
    Rake::Task["ideals_dspace:metadata:migrate_collection_values"].invoke(dbname, dbhost, dbuser)
    puts "WARNING: This is the last step, but it takes a long time. "\
        "You can ctrl+c at any time if you don't need full item metadata."
    Rake::Task["ideals_dspace:metadata:migrate_item_values"].invoke(dbname, dbhost, dbuser)
  end

  def do_migrate(source_db_name, source_db_host, source_db_user,
                 in_sql_file, import_method)
    out_csv_file = in_sql_file.gsub(/.sql$/i, ".csv")
    in_sql_file = File.join(Rails.root, "scripts", in_sql_file)
    Dir.mktmpdir do |dir|
      out_csv_file = File.join(dir, out_csv_file)
      if source_db_host.present?
        system sprintf("psql -h %s -U %s -d %s -f '%s' > '%s'",
                       source_db_host,
                       source_db_user,
                       source_db_name,
                       in_sql_file,
                       out_csv_file)
      else
        system sprintf("psql -d %s -f '%s' > '%s'",
                       source_db_name,
                       in_sql_file,
                       out_csv_file)
      end
      IdealsImporter.instance.send(import_method, out_csv_file)
    end
  end

end
