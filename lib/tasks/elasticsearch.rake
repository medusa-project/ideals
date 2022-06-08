namespace :elasticsearch do

  namespace :indexes do

    desc 'Copy the current index into the latest index'
    task :copy, [:from_index, :to_index] => :environment do |task, args|
      puts ElasticsearchClient.instance.reindex(args[:from_index], args[:to_index])
    end

    desc 'Create an index'
    task :create, [:name] => :environment do |task, args|
      client = ElasticsearchClient.instance
      unless client.index_exists?(args[:name])
        client.create_index(args[:name])
      end
    end

    desc 'Create an index alias'
    task :create_alias, [:index_name, :alias_name] => :environment do |task, args|
      index_name = args[:index_name]
      alias_name = args[:alias_name]
      client     = ElasticsearchClient.instance
      if client.index_exists?(alias_name)
        client.delete_index_alias(index_name, alias_name)
      end
      client.create_index_alias(index_name, alias_name)
    end

    desc 'Delete an index by name'
    task :delete, [:name] => :environment do |task, args|
      ElasticsearchClient.instance.delete_index(args[:name])
    end

    desc 'Delete an index alias by name'
    task :delete_alias, [:index_name, :alias_name] => :environment do |task, args|
      ElasticsearchClient.instance.
          delete_index_alias(args[:index_name], args[:alias_name])
    end

    desc 'List indexes'
    task :list => :environment do
      puts ElasticsearchClient.instance.indexes
    end

  end

  namespace :tasks do

    desc 'Delete a task'
    task :delete, [:id] => :environment do |task, args|
      ElasticsearchClient.instance.delete_task(args[:id])
    end

    desc 'Show the status of a task'
    task :show, [:id] => :environment do |task, args|
      puts JSON.pretty_generate(ElasticsearchClient.instance.get_task(args[:id]))
    end

  end

  desc 'Purge all documents from the index'
  task :purge => :environment do
    ElasticsearchClient.instance.purge
  end

  desc "Purge all documents that have no database counterparts"
  task :purge_orphaned_docs => :environment do
    Unit.delete_orphaned_documents
    Collection.delete_orphaned_documents
    Item.delete_orphaned_documents
  end

  desc 'Execute an arbitrary query'
  task :query, [:file] => :environment do |task, args|
    file_path = File.expand_path(args[:file])
    json      = File.read(file_path)
    puts ElasticsearchClient.instance.query(json)

    config = Configuration.instance
    curl_cmd = sprintf('curl -X POST -H "Content-Type: application/json" '\
        '"%s/%s/_search?pretty&size=0" -d @"%s"',
                       config.elasticsearch[:endpoint],
                       config.elasticsearch[:index],
                       file_path)
    puts 'cURL equivalent: ' + curl_cmd
  end

  desc 'Refresh'
  task :refresh => :environment do
    ElasticsearchClient.instance.refresh
  end

  desc 'Reindex all database entities'
  task :reindex, [:num_threads] => :environment do |task, args|
    # N.B.: orphaned documents are not deleted.
    num_threads = args[:num_threads].to_i
    num_threads = 1 if num_threads == 0
    Unit.reindex_all(num_threads: num_threads)
    Collection.reindex_all(num_threads: num_threads)
    Item.reindex_all(num_threads: num_threads)
  end

end
