require 'travis/amqp'
require 'travis/event'
require 'travis/exceptions'
require 'travis/instrumentation'
require 'travis/logger'
require 'travis/metrics'

require 'travis/addons'
require 'travis/hub/config'
require 'travis/hub/handler/metrics'
require 'travis/hub/model'
require 'travis/hub/support/database'
require 'travis/hub/support/redis_pool'
require 'travis/hub/support/sidekiq'

module Travis
  module Hub
    class App
      class Context
        attr_reader :amqp, :config, :exceptions, :logger, :metrics, :redis

        def initialize(options = {})
          @config     = Config.load
          @logger     = options[:logger] || Logger.new(STDOUT, config)
          @amqp       = Amqp.setup(config.amqp)
          @redis      = RedisPool.new(config.redis.to_h)
          @exceptions = Exceptions.setup(config, config.env, logger)
          @metrics    = Metrics.setup(config.metrics, logger)
        end

        def setup
          # TODO what's with the metrics handler. do we still need that? add it to the config?
          Database.connect(ActiveRecord::Base, config.database, logger)
          Addons.setup(config, logger)
          Event.setup(config.notifications, logger)
          Instrumentation.setup(logger)
          Sidekiq.setup(config)

          # TODO remove, message travis-logs instead
          [Log, Log::Part].each do |const|
            Database.connect(const, config.logs_database.to_h, logger)
          end

          # test_exception_reporting
        end

        private

          def declare_exchanges_and_queues(amqp)
            channel = amqp.connection.create_channel
            channel.exchange('reporting', durable: true, auto_delete: false, type: :topic)
            channel.queue('builds.linux', durable: true, exclusive: false)
          end

          def test_exception_reporting
            Travis::Exceptions.info(StandardError.new('Testing Sentry'), tags: { app: :hub, testing: true })
          end
      end
    end
  end
end
