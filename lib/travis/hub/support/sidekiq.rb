require 'sidekiq'
require 'travis/hub/support/sidekiq/log_format'
require 'travis/hub/support/sidekiq/metrics'
require 'travis/hub/support/sidekiq/sentry'

module Travis
  module Hub
    module Sidekiq
      def self.setup(config)
        ::Sidekiq::Logging.logger.level = Logger::WARN

          ::Sidekiq.configure_server do |c|
            c.redis = {
              url: config.redis.url,
              namespace: config.sidekiq.namespace
            }

            c.server_middleware do |chain|
              chain.add Support::Sidekiq::Sentry if config.sentry.dsn
              chain.add Support::Sidekiq::Metrics
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
end

