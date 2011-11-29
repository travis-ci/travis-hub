require 'travis'
require 'multi_json'
require 'hashr'
require 'benchmark'

module Travis
  class Hub
    autoload :Handler, 'travis/hub/handler'

    include Logging

    REPORTING_KEY = 'reporting.jobs'

    class << self
      def start
        Database.connect
        Travis::Mailer.setup

        start_newrelic

        prune_workers
        # cleanup_jobs
        subscribe
      end

      def subscribe
        new.subscribe
      end

      def prune_workers
        run_periodically(Travis.config.workers.prune.interval, &::Worker.method(:prune))
      end

      def cleanup_jobs
        run_periodically(Travis.config.jobs.retry.interval, &::Job.method(:cleanup))
      end

      def start_newrelic
        begin
          puts "Starting New Relic with env:#{ENV['ENV']}"
          require 'newrelic_rpm'
          NewRelic::Agent.manual_start(:env => ENV['ENV'])
        rescue Exception => e
          puts 'New Relic Agent refused to start!'
          puts e.message
          puts e.backtrace
        end
      end

      protected

        def run_periodically(interval, &block)
          Thread.new do
            loop do
              block.call
              sleep(interval)
            end
          end
        end
    end

    attr_reader :config

    def initialize
      @config = Travis.config.amqp
    end

    def subscribe
      log 'Subscribing to amqp ...'
      Travis::Amqp.subscribe(:ack => true, &method(:receive))
    end

    def receive(message, payload)
      notice "Handling event #{message.properties.type.inspect} with payload : #{(payload.size > 80 ? "#{payload[0..80]} ..." : payload)}"

      benchmark_and_cache do
        event   = message.properties.type
        payload = decode(payload)
        handler = Handler.for(event, payload)
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
        notice "Completed in #{timing.round(4)} seconds"
      end

      def decode(payload)
        MultiJson.decode(payload)
      end
  end
end
