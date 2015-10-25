require 'travis/addons'
require 'travis/event'
require 'travis/exceptions'
require 'travis/instrumentation'
require 'travis/logger'
require 'travis/metrics'

require 'travis/hub/app/dispatcher'
require 'travis/hub/app/solo'
require 'travis/hub/app/worker'
require 'travis/hub/config'
require 'travis/hub/handler/metrics'
require 'travis/hub/model'
require 'travis/hub/service'
require 'travis/hub/support/database'
require 'travis/hub/support/amqp'
require 'travis/hub/support/sidekiq'

# TODO what's with the metrics handler. do we still need that? add it to the config?

module Travis
  module Hub
    class Context
      def self.setup
        context = new
        config, logger = context.config, context.logger

        Database.connect(config.database, logger)
        Addons.setup(config, logger)
        Event.setup(config.notifications)
        Instrumentation.setup(logger)
        Sidekiq.setup(config)

        # TODO remove, message travis-logs instead
        [Log, Log::Part].each do |const|
          const.establish_connection(config.logs_database.to_h)
        end
      end

      attr_reader :amqp, :config, :exceptions, :logger, :metrics

      def initialize(options = {})
        @config     = Config.load
        @logger     = options[:logger] || Logger.new(STDOUT, config)
        @amqp       = Amqp.setup(config.amqp)
        @exceptions = Exceptions.setup(config, config.env, logger)
        @metrics    = Metrics.setup(config, logger)
      end

      def logger=(logger)
        @logger = Logger.configure(logger)
      end
    end

    module App
      class << self
        MODES = { solo: Solo, worker: Worker, dispatcher: Dispatcher }

        attr_reader :context

        def run(mode, options)
          # TODO remove Hub.context
          Hub.context = context = Context.setup
          MODES.fetch(mode).new(context, mode, options).run
        end
      end
    end
  end
end
