require 'multi_json'
require 'benchmark'
require 'active_support/core_ext/float/rounding'
require 'core_ext/kernel/run_periodically'
require 'core_ext/hash/compact'

require 'travis'
require 'travis/support'

$stdout.sync = true

module Travis
  class Hub
    autoload :Handler,    'travis/hub/handler'
    autoload :Instrument, 'travis/hub/instrument'
    autoload :Error,      'travis/hub/error'

    include Logging

    class << self
      def start
        setup
        prune_workers
        enqueue_jobs
        new.subscribe
      end

      protected

        def setup
          Travis::Async.enabled = true
          Travis.config.update_periodically

          Travis::Exceptions::Reporter.start
          Travis::Notification.setup

          Travis::Database.connect
          Travis::Mailer.setup
          Travis::Features.start
          Travis::Amqp.config = Travis.config.amqp

          GH::DefaultStack.options[:ssl] = Travis.config.ssl

          NewRelic.start if File.exists?('config/newrelic.yml')
        end

        def prune_workers
          run_periodically(Travis.config.workers.prune.interval, &::Worker.method(:prune))
        end

        def enqueue_jobs
          run_periodically(Travis.config.jobs.queue.interval) { Job::Queueing::All.new.run }
        end

        # def cleanup_jobs
        #   run_periodically(Travis.config.jobs.retry.interval, &::Job.method(:cleanup))
        # end
    end

    def subscribe
      info 'Subscribing to amqp ...'

      queues = ['builds.requests', 'sync.user']
      queues.each do |queue|
        info "Subscribing to #{queue}"
        Travis::Amqp::Consumer.new(queue).subscribe(:ack => true, &method(:receive))
      end

      queues = ['builds.common'] + Travis.config.queues.map { |queue| queue[:queue] }
      queues.uniq.each do |name|
        info "Subscribing to #{name}"
        Travis::Amqp::Consumer.jobs(name).subscribe(:ack => true, &method(:receive))
      end

      Travis::Amqp::Consumer.workers.subscribe(:ack => true, &method(:receive))
    end

    def receive(message, payload)
      event = message.properties.type
      # TODO move to instrumentation or remove?
      debug "[#{Thread.current.object_id}] Handling event #{event.inspect} with payload : #{(payload.size > 160 ? "#{payload[0..160]} ..." : payload)}"

      payload = decode(payload)
      Travis.uuid = payload.delete('uuid')

      with(:timeout, :benchmarking, :caching) do
        Handler.handle(event, payload) if payload
      end

    rescue Exception => e
      begin
        puts e.message, e.backtrace
        Travis::Exceptions.handle(Hub::Error.new(event, payload, e))
      rescue Exception => e
        puts "!!!FAILSAFE!!! #{e.message}", e.backtrace
      end

    ensure
      message.ack
    end

    protected

      def timeout(&block)
        Timeout::timeout(60, &block)
      end

      def benchmarking(&block)
        timing = Benchmark.realtime(&block)
        debug "[#{Thread.current.object_id}] Completed in #{timing.round(4)} seconds"
      end

      def caching(&block)
        defined?(ActiveRecord) ? ActiveRecord::Base.cache(&block) : block.call
      end

      def decode(payload)
        MultiJson.decode(payload)
      rescue StandardError => e
        error "[#{Thread.current.object_id}] [decode error] payload could not be decoded with engine #{MultiJson.engine.to_s} : #{e.inspect}"
        nil
      end

      def with(*methods, &block)
        if methods.size > 1
          head = methods.shift
          with(*methods) { send(head, &block) }
        else
          send(methods.first, &block)
        end
      end
  end
end
