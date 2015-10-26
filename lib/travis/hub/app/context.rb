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
require 'travis/hub/support/sidekiq'
module Travis
  module Metrics
    module Reporter
      class << self
        def librato(config, logger)
          require 'metriks/librato_metrics_reporter'
          email, token = config[:email], config[:token]
          return unless email && token
          source = config[:source]
          source = "#{source}.#{ENV['DYNO']}" if ENV.key?('DYNO')
          on_error = proc {|ex| puts "librato error: #{ex.message} (#{ex.response.body})"}
          puts "Using Librato metrics reporter (source: #{source}, account: #{email})"
          Metriks::LibratoMetricsReporter.new(email, token, source: source, on_error: on_error)
        end

        def graphite(config, logger)
          require 'metriks/reporter/graphite'
          host, port = *config.values_at(:host, :port)
          return unless host
          puts "Using Graphite metrics reporter (host: #{host}, port: #{port})"
          Metriks::Reporter::Graphite.new(host, port)
        end
      end
    end

    METRICS_VERSION = 'v1'

    class << self
      attr_reader :reporter

      def setup(config, logger)
        adapter   = config[:reporter]
        config    = config[adapter.to_sym] || {} if adapter
        @reporter = Reporter.send(adapter, config, logger)
        reporter ? reporter.start : logger.info('No metrics reporter configured.')
        self
      rescue Exception => e
        puts "Exception while starting metrics reporter: #{e.message}", e.backtrace
      end

      def started?
        !!reporter
      end

      def meter(event, options = {})
        return if !started? || options[:level] == :debug

        event = "#{METRICS_VERSION}.#{event}"
        started_at, finished_at = options[:started_at], options[:finished_at]

        if finished_at
          Metriks.timer(event).update(finished_at - started_at)
        else
          Metriks.meter(event).mark
        end
      end
    end
  end
end

module Travis
  module Hub
    class App
      class Context
        attr_reader :amqp, :config, :exceptions, :logger, :metrics

        def initialize(options = {})
          @config     = Config.load
          @logger     = options[:logger] || Logger.new(STDOUT, config)
          @amqp       = Amqp.setup(config.amqp)
          @exceptions = Exceptions.setup(config, config.env, logger)
          @metrics    = Metrics.setup(config.metrics, logger)
        end

        def setup
          # TODO what's with the metrics handler. do we still need that? add it to the config?
          Database.connect(config.database, logger)
          Addons.setup(config, logger)
          Event.setup(config.notifications, logger)
          Instrumentation.setup(logger)
          Sidekiq.setup(config)

          # TODO remove, message travis-logs instead
          [Log, Log::Part].each do |const|
            const.establish_connection(config.logs_database.to_h)
          end
        end

        private

          def declare_exchanges_and_queues(amqp)
            channel = amqp.connection.create_channel
            channel.exchange('reporting', durable: true, auto_delete: false, type: :topic)
            channel.queue('builds.linux', durable: true, exclusive: false)
          end
      end
    end
  end
end
