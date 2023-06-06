require 'rake'

namespace :collections do

  desc "Reindex all collections"
  task :reindex, [:num_threads] => :environment do |task, args|
    # N.B.: orphaned documents are not deleted.
    num_threads = args[:num_threads].to_i
    num_threads = 1 if num_threads == 0
    Collection.reindex_all(num_threads: num_threads)
  end

end