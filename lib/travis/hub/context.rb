require 'travis/event'
require 'travis/exceptions'
require 'travis/instrumentation'
require 'travis/logger'
require 'travis/metrics'

require 'travis/addons'
require 'travis/hub/config'
require 'travis/hub/event/metrics'
require 'travis/hub/model'
require 'travis/hub/support/amqp'
require 'travis/hub/support/database'
require 'travis/hub/support/redis_pool'
require 'travis/hub/support/sidekiq'

module Travis
  module Hub
    class Context
      ADDONS = %w(
        github_status scheduler email flowdock hipchat irc pusher pushover
        slack states_cache webhook
      )

      attr_reader :config, :logger, :metrics, :exceptions, :redis, :amqp

      def initialize(options = {})
        @config     = Config.load
        @logger     = options[:logger] || Travis::Logger.new(STDOUT, config)
        @exceptions = Travis::Exceptions.setup(config, config.env, logger)
        @metrics    = Travis::Metrics.setup(config.metrics, logger)
        @redis      = Travis::RedisPool.new(config.redis.to_h)
        @amqp       = Travis::Amqp.setup(config.amqp)

        Travis::Database.connect(ActiveRecord::Base, config.database, logger)
        Travis::Sidekiq.setup(config)
        Travis::Addons.setup(config, logger)
        Travis::Event.setup(ADDONS, logger)
        Travis::Instrumentation.setup(logger)

        # TODO remove, message travis-logs instead
        [Log, Log::Part].each do |const|
          Travis::Database.connect(const, config.logs_database.to_h, logger)
        end

        # TODO remove Hub.context
        Hub.context = self

        # test_exception_reporting
      end


      private

        def test_exception_reporting
          exceptions.info(StandardError.new('Testing Sentry'), tags: { app: :hub, testing: true })
        end
    end
  end
end
