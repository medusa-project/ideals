namespace :elasticsearch do

  namespace :indexes do

    desc 'Copy the current index into the latest index'
    task :copy, [:from_index, :to_index] => :environment do |task, args|
      ElasticsearchClient.instance.reindex(args[:from_index], args[:to_index])
    end

    desc 'Create an index'
    task :create, [:name] => :environment do |task, args|
      ElasticsearchClient.instance.create_index(args[:name])
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

  desc 'Purge all documents from the current index'
  task :purge => :environment do
    ElasticsearchClient.instance.purge
  end

  desc 'Execute an arbitrary query against the default index'
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

  desc 'Reindex all database entities'
  task reindex: :environment do
    Unit.reindex_all
    Collection.reindex_all
    Item.reindex_all
    # TODO: delete indexed docs whose database rows have been deleted
  end

end
