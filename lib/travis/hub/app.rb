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
        TYPES = { 'solo' => Solo, 'worker' => Worker, 'dispatcher' => Dispatcher }

        def run(type, *args)
          setup
          setup_worker unless type == 'dispatcher'
          TYPES.fetch(type).new(type, *args).run
        end

        def setup
          Travis::Database.connect
          Support::Amqp.setup(config.amqp)
          Travis::Metrics.setup
        end

        def setup_worker
          setup_logs_database
          Support::Sidekiq.setup(config)

          # TODO what's with the metrics handler. do we still need that? add it to the config?
          Travis::Event.setup(config.notifications)
          Travis::Instrumentation.setup(logger)
          Travis::Exceptions::Reporter.start if config.env == :production
          Travis::Encrypt.setup(key: config.encryption)

          # Travis.logger = Logger.configure(Logger.new(STDOUT))
        end

        def setup_logs_database # TODO remove
          [Log, Log::Part].each do |const|
            const.establish_connection(config.logs_database)
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