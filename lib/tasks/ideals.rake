require 'rake'

namespace :ideals do

  namespace :cache do
    desc "Clear Rails cache (sessions, views, etc.)"
    task clear: :environment do
      Rails.cache.clear
    end
  end

  namespace :collections do
    desc "Delete all collections"
    task delete: :environment do
      ActiveRecord::Base.transaction do
        Collection.all.destroy_all
      end
    end
  end

  namespace :handles do
    desc "Delete all handles"
    task delete: :environment do
      ActiveRecord::Base.transaction do
        Handle.all.destroy_all
      end
    end
  end

  namespace :items do
    desc "Delete all items"
    task delete: :environment do
      ActiveRecord::Base.transaction do
        Item.all.destroy_all
      end
    end
  end

  namespace :units do
    desc "Delete all units"
    task delete: :environment do
      ActiveRecord::Base.transaction do
        Unit.all.destroy_all
      end
    end
  end

  namespace :users do
    desc "Create a local sysadmin user"
    task :create_local_sysadmin, [:username, :password] => :environment do |task, args|
      username = args[:username]
      ActiveRecord::Base.transaction do
        user = LocalUser.no_omniauth("#{username}@example.edu")
        user.update!(sysadmin: true)
        LocalIdentity.create_for_user(user, args[:password])
      end
    end

    desc "Create a Shibboleth user"
    task :create_shibboleth, [:netid] => :environment do |task, args|
      email = "#{args[:netid]}@illinois.edu"
      user = ShibbolethUser.no_omniauth(email)
      user.save!
    end

    desc 'Delete a user'
    task :delete, [:netid] => :environment do |task, args|
      netid = args[:netid]
      email = "#{netid}@illinois.edu"
      ActiveRecord::Base.transaction do
        LocalIdentity.destroy_by(email: email)
        Invitee.destroy_by(email: email)
        User.destroy_by(email: email)
      end
    end
  end

  desc "Seed the database (AFTER MIGRATION)"
  task seed: :environment do
    IdealsSeeder.new.seed
  end

end
