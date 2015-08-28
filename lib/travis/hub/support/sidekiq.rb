require 'sidekiq'

module Travis
  module Hub
    module Support
      module Sidekiq
        def self.setup(config)
          ::Sidekiq::Logging.logger.level = Logger::WARN

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
end
