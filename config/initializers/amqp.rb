amqp_settings_path = File.join(Rails.root, 'config', 'amqp.yml')
amqp_settings = YAML.load(ERB.new(File.read(amqp_settings_path)).result, aliases: true)[Rails.env]

# this is provided by the amqp_helper gem
AmqpHelper::Connector.new(:ideals, amqp_settings)
