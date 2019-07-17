VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
IDEALS_CONFIG = YAML.load(ERB.new(File.read(File.join(Rails.root, 'config', 'ideals.yml'))).result)

if Rails.env.development?
  # create local identity accounts for admins
  admins = IDEALS_CONFIG[:admin][:netids].split(",").collect {|x| x.strip || x}
  admins.each do |netid|

    email = "#{netid}@illinois.edu"
    name = "admin #{netid}"
    invitee = Invitee.find_by_email(email) || Invitee.create!(email: email, approved: true)
    invitee.role = Ideals::UserRole::ADMIN
    invitee.expires_at = Time.zone.now + 1.years
    invitee.save!
    identity = Identity.find_or_create_by(email: email)
    salt = BCrypt::Engine.generate_salt
    localpass = IDEALS_CONFIG[:admin][:localpass]
    encrypted_password = BCrypt::Engine.hash_secret(localpass, salt)
    identity.password_digest = encrypted_password
    identity.update_attributes(password: localpass, password_confirmation: localpass)
    identity.name = name
    identity.activated = true
    identity.activated_at = Time.zone.now
    identity.save!
  end

end