require 'coder'
require 'travis/hub/app/error'

module Travis
  module Hub
    module App
      class Queue
        include Logging

        def self.subscribe(queue, options = {}, &handler)
          new(queue, options, &handler).subscribe
        end

        attr_reader :queue, :options, :handler

        def initialize(queue, options, &handler)
          @queue   = queue
          @options = options.merge(ack: true)
          @handler = handler
        end

        def subscribe
          Amqp::Consumer.jobs(queue).subscribe(options, &method(:receive))
        end

        private

          def receive(message, payload)
            failsafe(message, payload) do
              type = message.properties.type
              payload = decode(payload)
              handler.call(type, payload)
            end
          end

          def failsafe(message, payload, options = {}, &block)
            Timeout.timeout(options[:timeout] || 60, &block)
          rescue Exception => e
            begin
              puts e.message, e.backtrace
              Exceptions.handle(Error.new(message.properties.type, payload, e))
            rescue => e
              puts "!!!FAILSAFE!!! #{e.message}", e.backtrace
            end
          ensure
            message.ack
          end

          def decode(payload)
            cleaned = Coder.clean(payload)
            decoded = MultiJson.decode(cleaned)
            decoded || fail("No payload for #{event.inspect} (#{message.inspect})")
          rescue StandardError => e
            error '[decode error] payload could not be decoded with engine ' \
                  "#{MultiJson.engine}: #{e.inspect} #{payload.inspect}"
            nil
          end
      end
    end
  end
end
