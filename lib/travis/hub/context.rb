require 'travis/event'
require 'travis/exceptions'
require 'travis/instrumentation'
require 'travis/logger'
require 'travis/metrics'
require 'travis/addons'
require 'travis/honeycomb'
require 'travis/hub/config'
require 'travis/hub/model'
require 'travis/hub/support/amqp'
require 'travis/hub/support/database'
require 'travis/hub/support/redis_pool'
require 'travis/hub/support/sidekiq'
require 'travis/marginalia'


module Travis
  module Hub
    class Context
      attr_reader :config, :logger, :metrics, :exceptions, :redis, :amqp

      def initialize(options = {})
        @config     = Config.load
        @logger     = options[:logger] || Travis::Logger.new(STDOUT, config)
        @exceptions = Travis::Exceptions.setup(config, config.env, logger)
        @metrics    = Travis::Metrics.setup(config.metrics, logger)
        @redis      = Travis::RedisPool.new(config.redis.to_h)
        @amqp       = Travis::Amqp.setup(config.amqp, @config.enterprise?)

        Travis::Database.connect(ActiveRecord::Base, config.database, logger)
        Travis::Sidekiq.setup(config)
        Travis::Addons.setup(config, logger)
        Travis::Event.setup(addons, logger)
        Travis::Instrumentation.setup(logger)

        Travis::Honeycomb::Context.add_permanent('app', 'hub')
        Travis::Honeycomb::Context.add_permanent('dyno', ENV['DYNO'])
        Travis::Honeycomb::Context.add_permanent('site', ENV['TRAVIS_SITE'])
        Travis::Honeycomb.setup(logger)

        if ENV['QUERY_COMMENTS_ENABLED'] == 'true'
          Travis::Marginalia.setup
        end

        # TODO remove Hub.context
        Hub.context = self

        # test_exception_reporting
      end

      private

        def addons
          # TODO move keen to the keychain? it isn't required on enterprise.
          # then again, it's not active, unless the keen credentials are
          # present in the env.
          addons = config.notifications.flatten + ['insights', 'logsearch', 'scheduler', 'keenio', 'metrics']
          addons << 'merge' if ENV['NOTIFY_MERGE']
          addons
        end

        def pluralize_addons(addons, names)
          names.each do |name|
            addons << "#{name}s" if addons.delete(name)
          end
        end

        def test_exception_reporting
          exceptions.info(StandardError.new('Testing Sentry'), tags: { app: :hub, testing: true })
        end
    end
  end
end
