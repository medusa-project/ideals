require 'rake'

namespace :users do

  desc "Create a local-credentials user"
  task :create_local, [:email, :password, :name, :institution_key] => :environment do |task, args|
    institution = Institution.find_by_key(args[:institution_key])
    raise ArgumentError, "Institution not found: #{institution}" unless institution
    user = User.create_local(email:       args[:email],
                             password:    args[:password],
                             name:        args[:name],
                             institution: institution)
    user.save!
  end

  desc "Create a local-credentials sysadmin user"
  task :create_local_sysadmin, [:email, :password, :name, :institution_key] => :environment do |task, args|
    institution = Institution.find_by_key(args[:institution_key])
    raise ArgumentError, "Institution not found: #{institution}" unless institution
    user = User.create_local(email:       args[:email],
                             password:    args[:password],
                             name:        args[:name],
                             institution: institution)
    user.user_groups << UserGroup.sysadmin
    user.save!
  end

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

  desc "Make a user a unit administrator"
  task :make_unit_admin, [:email, :unit_id] => :environment do |task, args|
    user = User.find_by_email(args[:email])
    unit = Unit.find(args[:unit_id])
    unit.administering_users << user
    unit.save!
  end

end