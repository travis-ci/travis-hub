require 'travis'
require 'multi_json'
require 'hashr'
require 'benchmark'
require 'core_ext/module/include'
require 'travis/support'

module Travis
  class Hub
    autoload :Handler,    'travis/hub/handler'
    autoload :Monitoring, 'travis/hub/monitoring'

    include Logging

    class << self
      def start
        Database.connect
        Travis::Mailer.setup

        Monitoring.start

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

    include do
      def initialize
        Travis::Amqp.config = Travis.config.amqp
      end

      def subscribe
        info 'Subscribing to amqp ...'
        Travis::Amqp::Consumer.jobs.subscribe(:ack => true, &method(:receive))
        Travis::Amqp::Consumer.workers.subscribe(:ack => true, &method(:receive))
      end

      def receive(message, payload)
        info "Handling event #{message.properties.type.inspect} with payload : #{(payload.size > 80 ? "#{payload[0..80]} ..." : payload)}"

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
          info "Completed in #{timing.round(4)} seconds"
        end

        def decode(payload)
          MultiJson.decode(payload)
        end
    end
  end
end
