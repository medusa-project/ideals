require 'rake'

namespace :users do

  desc 'Delete a user'
  task :delete, [:email] => :environment do |task, args|
    User.destroy_by(email: args[:email])
  end

  desc "Make a user an institution administrator"
  task :make_institution_admin, [:email, :institution_key] => :environment do |task, args|
    user        = User.find_by_email(args[:email])
    institution = Institution.find_by_key(args[:institution_key])
    institution.administering_users << user
    institution.save!
  end

  desc "Make a user a sysadmin"
  task :make_sysadmin, [:email] => :environment do |task, args|
    user = User.find_by_email(args[:email])
    group = UserGroup.sysadmin
    group.users << user
    group.save!
  end

  desc "Make a user a unit administrator"
  task :make_unit_admin, [:email, :unit_id] => :environment do |task, args|
    user = User.find_by_email(args[:email])
    unit = Unit.find(args[:unit_id])
    unit.administering_users << user
    unit.save!
  end

end