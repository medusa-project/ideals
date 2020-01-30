require 'rake'

namespace :ideals_dspace do

  namespace :collections do
    desc "Migrate collections from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 "export_collections.sql",
                 :import_collections)
      do_migrate(args[:source_db_name],
                 "export_collections_2_communities.sql",
                 :import_collections_2_communities)
    end
  end

  namespace :communities do
    desc "Migrate communities from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name] => :environment do |task, args|
      do_migrate(args[:source_db_name],
                 "export_communities.sql",
                 :import_communities)
      do_migrate(args[:source_db_name],
                 "export_communities_2_communities.sql",
                 :import_communities_2_communities)
    end
  end

  namespace :handles do
    desc "Migrate handles from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name] => :environment do |task, args|
      do_migrate(args[:source_db_name], "export_handles.sql", :import_handles)
    end
  end

  namespace :items do
    desc "Migrate items from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name] => :environment do |task, args|
      do_migrate(args[:source_db_name], "export_items.sql", :import_items)
    end
  end

  namespace :metadata do
    desc "Migrate metadata from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name] => :environment do |task, args|
      do_migrate(args[:source_db_name], "export_metadata.sql", :import_metadata)
    end
  end

  desc "Migrate all content from IDEALS-DSpace into the application"
  task :migrate, [:source_db_name] => :environment do |task, args|
    dbname = args[:source_db_name]
    Rake::Task["ideals_dspace:communities:migrate"].invoke(dbname)
    Rake::Task["ideals_dspace:collections:migrate"].invoke(dbname)
    Rake::Task["ideals_dspace:items:migrate"].invoke(dbname)
    Rake::Task["ideals_dspace:handles:migrate"].invoke(dbname)
    Rake::Task["ideals_dspace:metadata:migrate"].invoke(dbname)
  end

  def do_migrate(source_db_name, in_sql_file, import_method)
    out_csv_file = in_sql_file.gsub(/.sql$/i, ".csv")
    in_sql_file = File.join(Rails.root, "scripts", in_sql_file)
    Dir.mktmpdir do |dir|
      out_csv_file = File.join(dir, out_csv_file)
      system "psql -d #{source_db_name} -f '#{in_sql_file}' > '#{out_csv_file}'"
      IdealsImporter.new.send(import_method, out_csv_file)
    end
  end

end
