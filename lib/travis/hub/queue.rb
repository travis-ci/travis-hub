require 'coder'

module Travis
  class Hub
    class Queue
      include Logging

      def self.subscribe(&handler)
        new(&handler).subscribe
      end

      attr_reader :handler

      def initialize(&handler)
        @handler = handler
      end

      def subscribe
        Travis::Amqp::Consumer.jobs('builds').subscribe(:ack => true, &method(:receive))
      end

      private

        def receive(message, payload)
          failsafe(message, payload) do
            event = message.properties.type
            payload = decode(payload) || raise("no payload for #{event.inspect} (#{message.inspect})")
            Travis.uuid = payload.delete('uuid')
            handler.call(event, payload)
          end
        end

        def failsafe(message, payload, options = {}, &block)
          Timeout::timeout(options[:timeout] || 60, &block)
        rescue Exception => e
          begin
            puts e.message, e.backtrace
            Travis::Exceptions.handle(Hub::Error.new(message.properties.type, payload, e))
          rescue Exception => e
            puts "!!!FAILSAFE!!! #{e.message}", e.backtrace
          end
        ensure
          message.ack
        end

        def decode(payload)
          cleaned = Coder.clean(payload)
          MultiJson.decode(cleaned)
        rescue StandardError => e
          error "[decode error] payload could not be decoded with engine #{MultiJson.engine.to_s}: #{e.inspect} #{payload.inspect}"
          nil
        end
    end
  end
end
