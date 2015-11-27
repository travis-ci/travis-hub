require 'sidekiq'
require 'travis/exceptions/sidekiq'
require 'travis/metrics/sidekiq'
require 'travis/hub/support/sidekiq/log_format'

module Travis
  module Sidekiq
    def self.setup(config)
      ::Sidekiq::Logging.logger.level = Logger::WARN

      ::Sidekiq.configure_server do |c|
        c.redis = {
          url: config.redis.url,
          namespace: config.sidekiq.namespace
        }

        c.server_middleware do |chain|
          chain.add Travis::Exceptions::Sidekiq if config.sentry.dsn
          chain.add Travis::Metrics::Sidekiq
        end

        c.logger.formatter = Support::Sidekiq::Logging.new(config.logger || {})
      end

      ::Sidekiq.configure_client do |c|
        c.redis = {
          url: config.redis.url,
          namespace: config.sidekiq.namespace
        }
      end
    end
  end
end
