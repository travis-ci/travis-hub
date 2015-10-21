require 'travis/support/database'
require 'travis/support/metrics'
require 'travis/addons'
require 'travis/event'

require 'travis/hub/app/dispatcher'
require 'travis/hub/app/solo'
require 'travis/hub/app/worker'
require 'travis/hub/model/log'
require 'travis/hub/model/log/part'
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
          Database.connect(config.database.to_h)
          Metrics.setup
          Support::Amqp.setup(config.amqp.to_h)
        end

        def setup_worker
          setup_logs_database # TODO remove, message travis-logs instead

          # TODO what's with the metrics handler. do we still need that? add it to the config?
          Addons.setup(config)
          Event.setup(config.notifications)
          Exceptions::Reporter.start if config.env == 'production'
          Instrumentation.setup(logger)
          Support::Sidekiq.setup(config)
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
