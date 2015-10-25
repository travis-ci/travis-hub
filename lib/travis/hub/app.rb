require 'travis/addons'
require 'travis/event'
require 'travis/exceptions'
require 'travis/instrumentation'
require 'travis/metrics'

require 'travis/hub/app/dispatcher'
require 'travis/hub/app/solo'
require 'travis/hub/app/worker'
require 'travis/hub/model/log'
require 'travis/hub/model/log/part'
require 'travis/hub/support/database'
require 'travis/hub/support/amqp'
require 'travis/hub/support/sidekiq'

module Travis
  module Hub
    module App
      class << self
        MODES = { solo: Solo, worker: Worker, dispatcher: Dispatcher }

        def run(mode, options)
          setup
          setup_worker unless mode == :dispatcher
          MODES.fetch(mode).new(mode, options).run
        end

        def setup
          Database.connect(config.database, logger)
          Metrics.setup(config, logger)
          Amqp.setup(config.amqp)
        end

        def setup_worker
          setup_logs_database # TODO remove, message travis-logs instead

          # TODO what's with the metrics handler. do we still need that? add it to the config?
          Addons.setup(config)
          Event.setup(config.notifications)
          Exceptions.setup(config, config.env, logger)
          Instrumentation.setup(logger)
          Sidekiq.setup(config)
        end

        def setup_logs_database
          [Log, Log::Part].each do |const|
            const.establish_connection(config.logs_database.to_h)
          end
        end

        def logger
          Hub.logger
        end

        def config
          Hub.config
        end
      end
    end
  end
end
