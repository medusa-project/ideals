VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
IDEALS_CONFIG = YAML.load(ERB.new(File.read(File.join(Rails.root, 'config', 'ideals.yml'))).result)
