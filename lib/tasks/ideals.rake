require 'rake'

namespace :ideals do
  namespace :rails_cache do
    desc "Clear Rails cache (sessions, views, etc.)"
    task clear: :environment do
      Rails.cache.clear
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
          user = User::User.no_omniauth(email, AuthProvider::SHIBBOLETH)
          user.roles << Role.find_by(name: "sysadmin") unless user.sysadmin?
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
          user = User::User.no_omniauth(email, AuthProvider::IDENTITY)
          user.roles << Role.find_by(name: "sysadmin") unless user.sysadmin?
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
        User::User.destroy_by(email: email)
      end
    end
  end
end
