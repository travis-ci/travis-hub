require 'travis'
require 'multi_json'
require 'hashr'
require 'benchmark'

module Travis
  class Hub
    autoload :Handler,    'travis/hub/handler'
    autoload :Processing, 'travis/hub/processing'

    include Logging

    REPORTING_KEY = 'reporting.jobs'

    class << self
      def start
        Database.connect
        Processing.start do
          prune_workers
          # cleanup_jobs
          subscribe
        end
      end

      def subscribe
        new.subscribe
      end

      def prune_workers
        interval = Travis.config.workers.prune.interval
        Processing.run_periodically(interval, &::Worker.method(:prune))
      end

      def cleanup_jobs
        interval = Travis.config.jobs.retry.interval
        Processing.run_periodically(interval, &::Job.method(:cleanup))
      end
    end

    attr_reader :config

    def initialize
      @config = Travis.config.amqp
    end

    def subscribe
      Travis::Amqp.subscribe(:ack => true, &method(:receive))
    end

    def receive(message, payload)
      log notice("Handling event #{message.type.inspect} with payload : #{payload.inspect}")

      event   = message.type
      payload = decode(payload)
      handler = Handler.for(event, payload)

      benchmark_and_cache do
        handler.handle
      end

      message.ack
    rescue Exception => e
      puts e.message, e.backtrace
      message.ack
      # message.reject(:requeue => false) # how to decide whether to requeue the message?
    end

    protected

      def benchmark_and_cache
        timing = Benchmark.realtime do
          ActiveRecord::Base.cache { yield }
        end
        log notice("Completed in #{timing.round(4)} seconds")
      end

      def decode(payload)
        MultiJson.decode(payload)
      end
  end
end
