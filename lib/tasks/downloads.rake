require 'rake'

namespace :downloads do

  ##
  # N.B.: this will take many hours to run the first time, but subsequent
  # monthly runs will be much faster.
  #
  # If stopped, this command will pick up where it left off when resumed.
  #
  desc "Compile monthly download counts"
  task compile_monthly_counts: :environment do
    MonthlyItemDownloadCount.compile_counts
  end

end