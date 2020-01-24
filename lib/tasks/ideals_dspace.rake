require 'rake'

namespace :ideals_dspace do

  ##
  # "Initializer" that configures the logger to log to stdout. All tasks that
  # want log output to be visible in the console should inherit from this.
  #
  task :custom_environment => :environment do
    logger       = Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    Rails.logger = logger
  end

  namespace :collections do
    desc "Migrate collections from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name] => :custom_environment do |task, args|
      do_migrate(args[:source_db_name],
                 File.join(Rails.root, "scripts", "export_collections.sql"),
                 :import_collections,
                 %w(/tmp/collections.csv /tmp/collection2community.csv))
    end
  end

  namespace :communities do
    desc "Migrate communities from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name] => :custom_environment do |task, args|
      do_migrate(args[:source_db_name],
                 File.join(Rails.root, "scripts", "export_communities.sql"),
                 :import_units,
                 %w(/tmp/communities.csv /tmp/community2community.csv))
    end
  end

  namespace :handles do
    desc "Migrate handles from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name] => :custom_environment do |task, args|
      do_migrate(args[:source_db_name],
                 File.join(Rails.root, "scripts", "export_handles.sql"),
                 :import_handles,
                 %w(/tmp/handles.csv))
    end
  end

  namespace :items do
    desc "Migrate items from IDEALS-DSpace into the application"
    task :migrate, [:source_db_name] => :custom_environment do |task, args|
      do_migrate(args[:source_db_name],
                 File.join(Rails.root, "scripts", "export_items.sql"),
                 :import_items,
                 %w(/tmp/items.csv))
    end
  end

  desc "Migrate all content from IDEALS-DSpace into the application"
  task :migrate, [:source_db_name] => :custom_environment do |task, args|
    Rake::Task["ideals_dspace:handles:migrate"].invoke(args[:source_db_name])
    Rake::Task["ideals_dspace:communities:migrate"].invoke(args[:source_db_name])
    Rake::Task["ideals_dspace:collections:migrate"].invoke(args[:source_db_name])
    Rake::Task["ideals_dspace:items:migrate"].invoke(args[:source_db_name])
  end

  def do_migrate(source_db_name, sql_file, import_method, csv_files)
    begin
      CustomLogger.new(Rake).info("Creating CSV using %s", sql_file)
      `psql -d #{source_db_name} -f "#{sql_file}"`
      IdealsImporter.new("/tmp").send(import_method)
    ensure
      csv_files.select{ |f| File.exists?(f) }.
          each{ |f| FileUtils.rm(f) }
    end
  end

end
