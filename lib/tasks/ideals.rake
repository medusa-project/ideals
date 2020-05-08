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
    task :create_local_sysadmin, [:email, :password] => :environment do |task, args|
      user = LocalUser.create_manually(email:    args[:email],
                                       password: args[:password])
      user.update!(sysadmin: true)
    end

    desc "Create a Shibboleth user"
    task :create_shibboleth, [:netid] => :environment do |task, args|
      email = "#{args[:netid]}@illinois.edu"
      user = ShibbolethUser.no_omniauth(email)
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
  end

  desc "Seed the database (AFTER MIGRATION)"
  task seed: :environment do
    IdealsSeeder.new.seed
  end

end
