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
    desc 'Create a user'
    task :create, [:netid, :localpass] => :environment do |task, args|
      netid = args[:netid]
      email = "#{netid}@illinois.edu"
      ActiveRecord::Base.transaction do
        case Rails.env
        when "demo", "production"
          user = ShibbolethUser.no_omniauth(email)
          user.save!
        else
          invitee = Invitee.find_by_email(email) || Invitee.create!(email: email,
                                                                    approval_state: ApprovalState::APPROVED)
          invitee.expires_at = Time.zone.now + 1.years
          invitee.save!
          identity = Identity.find_or_create_by(email: email)
          salt = BCrypt::Engine.generate_salt
          localpass = args[:localpass]
          encrypted_password = BCrypt::Engine.hash_secret(localpass, salt)
          identity.password_digest = encrypted_password
          identity.update(password: localpass, password_confirmation: localpass)
          identity.name = netid
          identity.activated = true
          identity.activated_at = Time.zone.now
          identity.save!
          user = IdentityUser.no_omniauth(email)
          user.sysadmin = true
          user.save!
        end
      end
    end

    desc 'Delete a user'
    task :delete, [:netid] => :environment do |task, args|
      netid = args[:netid]
      email = "#{netid}@illinois.edu"
      ActiveRecord::Base.transaction do
        Identity.destroy_by(name: netid)
        Invitee.destroy_by(email: email)
        User.destroy_by(email: email)
      end
    end
  end
end
