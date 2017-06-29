require 'sidekiq-pro'
require 'travis/exceptions/sidekiq'
require 'travis/metrics/sidekiq'
require 'travis/hub/support/sidekiq/log_format'

module Travis
  module Sidekiq
    def setup(config)
      ::Sidekiq::Logging.logger.level = Logger::WARN

      ::Sidekiq.configure_server do |c|
        if ENV['REDIS_GATEKEEPER_ENABLED'] == 'true'
          c.redis = {
            url: config.redis_gatekeeper.url,
            namespace: config.sidekiq.namespace
          }
        else
          c.redis = {
            url: config.redis.url,
            namespace: config.sidekiq.namespace
          }
        end

        c.server_middleware do |chain|
          chain.add Travis::Exceptions::Sidekiq if config.sentry && config.sentry.dsn
          chain.add Travis::Metrics::Sidekiq
        end

        c.logger.formatter = Support::Sidekiq::Logging.new(config.logger || {})

        if pro?
          c.reliable_fetch!
          c.reliable_scheduler!
        end
      end

      ::Sidekiq.configure_client do |c|
        c.redis = {
          url: config.redis.url,
          namespace: config.sidekiq.namespace
        }

        if pro?
          ::Sidekiq::Client.reliable_push!
        end
      end
    end

    def pro?
      ::Sidekiq::NAME == 'Sidekiq Pro'
    end

    extend self
  end
end
