# https://docs.aws.amazon.com/sdk-for-ruby/v3/api/index.html

require 'configuration'

config = ::Configuration.instance

opts = { region: config.aws[:region] }

# The access key ID and secret access key are only stored in the configuration
# in development and test. Demo & production use EC2 IAM credentials.
if Rails.env.development? || Rails.env.test?
  opts[:credentials] = Aws::Credentials.new(config.aws[:access_key_id],
                                            config.aws[:secret_access_key])
end

Aws.config.update(opts)
