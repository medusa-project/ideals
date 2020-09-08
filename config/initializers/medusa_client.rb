# Initializes the medusa-client gem.

require 'configuration'

config = ::Configuration.instance

Medusa::Client.configuration = {
    medusa_base_url: config.medusa[:base_url],
    medusa_user:     config.medusa[:user],
    medusa_secret:   config.medusa[:secret]
}
