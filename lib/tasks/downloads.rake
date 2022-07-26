require 'rake'

namespace :downloads do

  desc 'Clean up old downloads'
  task :cleanup => :environment do
    Download.cleanup(60 * 60 * 24) # max 1 day old
  end

  ##
  # N.B.: this will take many hours to run, but if stopped, it will pick up
  # where it left off when resumed.
  #
  desc "Compile monthly download counts"
  task compile_monthly_counts: :environment do
    MonthlyItemDownloadCount.compile_counts # this must be called first!
    MonthlyCollectionItemDownloadCount.compile_counts
    MonthlyUnitItemDownloadCount.compile_counts
    MonthlyInstitutionItemDownloadCount.compile_counts
  end

  desc 'Expire all downloads'
  task :expire => :environment do
    Download.where(expired: false).each(&:expire)
  end

  desc "Delete all downloads and their corresponding files"
  task :purge => :environment do
    count = Download.count
    Download.destroy_all
    puts "Deleted #{count} downloads"
  end

end