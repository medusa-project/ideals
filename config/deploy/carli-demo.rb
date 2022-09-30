# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

# server 'example.com', user: 'deploy', roles: %w{app db web}, my_property: :my_value
# server 'example.com', user: 'deploy', roles: %w{app web}, other_property: :other_value
# server 'db.example.com', user: 'deploy', roles: %w{db}
server 'scholarship-demo.scholarship.illinois.edu', user: 'ideals', roles: %w{app db web}

set :rails_env, 'demo'

set :ssh_options, {
  forward_agent: true,
  auth_methods: ["publickey"],
  keys: ["#{Dir.home}/.ssh/medusa_prod.pem"]
}

#ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call
set :branch, 'demo'

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/ideals'

