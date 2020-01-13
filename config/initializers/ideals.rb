# TODO: move this somewhere else
VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

# TODO: replace this with new configuration system and remove
IDEALS_CONFIG = YAML.load(ERB.new(File.read(File.join(Rails.root, 'config', 'ideals.yml'))).result)
