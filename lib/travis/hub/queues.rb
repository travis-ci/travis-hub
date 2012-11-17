require 'coder'

module Travis
  class Hub
    class Queues
      include Logging

      def self.subscribe
        new.subscribe
      end

      def subscribe
        info 'Subscribing to amqp ...'

        subscribe_to_build_requests_and_syncs
        subscribe_to_reporting
        subscribe_to_worker_status
      end

      def subscribe_to_build_requests_and_syncs
        queues = ['builds.requests', 'builds.requests', 'sync.user']
        queues.each do |queue|
          info "Subscribing to #{queue}"
          Travis::Amqp::Consumer.new(queue).subscribe(:ack => true, &method(:receive))
        end
      end

      def subscribe_to_reporting
        # TODO should be just 'builds', once we're on bluebox
        queues = ['builds', 'builds.common'] + Travis.config.queues.map { |queue| queue[:queue] }
        queues.uniq.each do |name|
          info "Subscribing to #{name}"
          Travis::Amqp::Consumer.jobs(name).subscribe(:ack => true, &method(:receive))
        end
      end

      def subscribe_to_worker_status
        info "Subscribing to reporting.workers"
        Travis::Amqp::Consumer.workers.subscribe(:ack => true, &method(:receive))
      end

      def receive(message, payload)
        event = message.properties.type
        # TODO move to instrumentation or remove?
        debug "[#{Thread.current.object_id}] Handling event #{event.inspect} with payload : #{(payload.size > 160 ? "#{payload[0..160]} ..." : payload)}"

        payload = decode(payload) || raise("no payload for #{event.inspect} (#{message.inspect})")
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
          cleaned = Coder.clean(payload)
          MultiJson.decode(cleaned)
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
end
