# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Role.create!(name: "sysadmin")

# TODO: this needs to be redesigned
case Rails.env
when "aws-demo", "aws-production"
  # create sysadmin role for system administrators defined in config file
  admins = IDEALS_CONFIG[:admin][:netids].split(",").collect {|x| x.strip || x}
  admins.each do |netid|
    email = "#{netid}@illinois.edu"
    user = User::User.no_omniauth(email, AuthProvider::SHIBBOLETH)
    user.roles << Role.find_by(name: "sysadmin") unless user.sysadmin?
    user.save!
  end
else
  # create local identity accounts and sysadmin role for system administrators defined in config file
  admins = IDEALS_CONFIG[:admin][:netids].split(",").collect {|x| x.strip || x}
  admins.each do |netid|
    email = "#{netid}@illinois.edu"
    name = "admin #{netid}"
    invitee = Invitee.find_by_email(email) || Invitee.create!(email: email, approval_state: ApprovalState::APPROVED)
    invitee.expires_at = Time.zone.now + 1.years
    invitee.save!
    identity = Identity.find_or_create_by(email: email)
    salt = BCrypt::Engine.generate_salt
    localpass = IDEALS_CONFIG[:admin][:localpass]
    encrypted_password = BCrypt::Engine.hash_secret(localpass, salt)
    identity.password_digest = encrypted_password
    identity.update(password: localpass, password_confirmation: localpass)
    identity.name = name
    identity.activated = true
    identity.activated_at = Time.zone.now
    identity.save!
    user = User::User.no_omniauth(email, AuthProvider::IDENTITY)
    user.roles << Role.find_by(name: "sysadmin") unless user.sysadmin?
    user.save!
  end
end
