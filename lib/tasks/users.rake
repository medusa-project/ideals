require 'rake'

namespace :users do

  desc "Create a local-identity user"
  task :create_local, [:email, :password, :name, :institution_key] => :environment do |task, args|
    user = LocalUser.create_manually(email:       args[:email],
                                     password:    args[:password],
                                     name:        args[:name],
                                     institution: Institution.find_by_key(args[:institution_key]))
    user.save!
  end

  desc "Create a local-identity sysadmin user"
  task :create_local_sysadmin, [:email, :password, :name, :institution_key] => :environment do |task, args|
    user = LocalUser.create_manually(email:       args[:email],
                                     password:    args[:password],
                                     name:        args[:name],
                                     institution: Institution.find_by_key(args[:institution_key]))
    user.user_groups << UserGroup.sysadmin
    user.save!
  end

  desc "Create a Shibboleth identity user"
  task :create_shib, [:email] => :environment do |task, args|
    user = ShibbolethUser.no_omniauth(args[:email])
    user.save!
  end

  desc "Create a Shibboleth identity sysadmin user"
  task :create_shib_sysadmin, [:email] => :environment do |task, args|
    user = ShibbolethUser.no_omniauth(args[:email])
    user.ad_groups << UserGroup.sysadmin.ad_groups.first
    user.save!
  end

  desc 'Delete a user'
  task :delete, [:email] => :environment do |task, args|
    email = args[:email]
    ActiveRecord::Base.transaction do
      LocalIdentity.destroy_by(email: email)
      Invitee.destroy_by(email: email)
      User.destroy_by(email: email)
    end
  end

  desc "Make a user a unit administrator"
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