require 'travis/hub/app/error'
require 'travis/hub/helper/context'

module Travis
  module Hub
    class App
      class Queue
        include Helper::Context

        attr_reader :context, :queue, :options, :handler

        def initialize(context, queue, options = {}, &handler)
          @context = context
          @queue   = queue
          @options = options.merge(ack: true)
          @handler = handler
        end

        def subscribe
          info "Subscribing to #{queue}."
          # TODO use context.amqp
          Travis::Amqp::Consumer.jobs(queue).subscribe(options, &method(:receive))
        end

        private

          def receive(message, payload)
            failsafe(message, payload) do
              type = message.properties.type
              payload = decode(payload)
              payload.delete('uuid') # TODO seems useless atm, and pollutes the log. decide what to do with these.
              handler.call(type, payload)
            end
          end

          def failsafe(message, payload, options = {}, &block)
            Timeout.timeout(options[:timeout] || 60, &block)
          rescue Exception => e
            begin
              puts e.message, e.backtrace
              handle_exception(Error.new(message.properties.type, payload, e))
            rescue => e
              puts "!!!FAILSAFE!!! #{e.message}", e.backtrace
            end
          ensure
            message.ack
          end

          def decode(payload)
            decoded = MultiJson.decode(payload)
            decoded || fail("No payload for #{event.inspect} (#{message.inspect})")
          rescue StandardError => e
            # TODO use Exceptions.handle
            error '[decode error] payload could not be decoded with engine ' \
              "#{MultiJson.engine}: #{e.inspect} #{payload.inspect}"
            nil
          end
      end
    end
  end
end
