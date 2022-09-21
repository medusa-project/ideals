# Configures the uiuc_lib_ad gem

require 'configuration'

app_config = ::Configuration.instance

UiucLibAd::Configuration.instance = UiucLibAd::Configuration.new(
  user:     app_config.ad[:user],
  password: app_config.ad[:password],
  server:   app_config.ad[:server],
  treebase: app_config.ad[:treebase]
)
