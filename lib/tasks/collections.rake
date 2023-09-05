require 'rake'

namespace :collections do

  desc "Reindex all collections"
  task reindex: :environment do
    # N.B.: orphaned documents are not deleted.
    Collection.bulk_reindex
  end

end