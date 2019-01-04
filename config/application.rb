require_relative 'boot'

require 'rails/all'
require 'base64'
require 'openssl'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Kingsly
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'application.yml')
      YAML.load(File.open(env_file)).each do |key, value|
        ENV[key.to_s] = value
      end if File.exists?(env_file)
    end

    config.load_defaults 5.2
    logger = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
    config.logger.level = Logger::ERROR
    config.read_encrypted_secrets = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
