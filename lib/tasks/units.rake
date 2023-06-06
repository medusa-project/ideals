require 'rake'

namespace :units do

  ##
  # See {Unit#move_to} for explanation and caveats.
  #
  desc "Move a unit to a different institution"
  task :move, [:unit_id, :institution_key, :user_email] => :environment do |task, args|
    unit        = Unit.find(args[:unit_id])
    institution = Institution.find_by_key(args[:institution_key])
    user        = User.find_by_email(args[:user_email])
    unit.move_to(institution: institution, user: user)
  end

  desc "Reindex all units"
  task :reindex, [:num_threads] => :environment do |task, args|
    # N.B.: orphaned documents are not deleted.
    num_threads = args[:num_threads].to_i
    num_threads = 1 if num_threads == 0
    Unit.reindex_all(num_threads: num_threads)
  end

end