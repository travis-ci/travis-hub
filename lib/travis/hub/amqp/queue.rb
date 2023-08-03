require 'coder'
require 'multi_json'
require 'travis/hub/amqp/error'
require 'travis/hub/helper/context'

module Travis
  module Hub
    class Amqp
      class Queue
        include Helper::Context

        attr_reader :context, :queue, :handler

        def initialize(context, queue, &handler)
          @context = context
          @queue   = queue
          @handler = handler
        end

        def subscribe
          info "Subscribing to #{queue}."
          # Travis::Amqp::Consumer.jobs(queue).subscribe(options, &method(:receive))
          context.amqp.subscribe(queue, manual_ack: true, &method(:receive))
        end

        private

        def receive(info, properties, payload)
          failsafe(info, properties, payload) do
            event = properties[:type] || raise("No type given on #{properties.inspect} (payload: #{payload.inspect})")
            payload = JSON.parse(payload) if payload.is_a?(String)
#            payload = decode(payload) || raise("No payload given: #{payload.inspect}")
            payload.delete('uuid') # TODO: seems useless atm, and pollutes the log. decide what to do with these.
            handler.call(event, payload)
          end
        end

        def failsafe(info, properties, payload, options = {}, &block)
          Timeout.timeout(options[:timeout] || 60, &block)
        rescue Exception => e
          handle_exception(e, info, properties:, payload:)
        ensure
          context.amqp.ack(info)
        end

        def decode(payload)
          cleaned = Coder.clean(payload) # TODO: not needed anymore? 
          MultiJson.decode(cleaned)
        rescue StandardError => e
          # TODO: use Exceptions.handle
          error '[decode error] payload could not be decoded with engine ' \
            "#{MultiJson.engine}: #{e.inspect} #{payload.inspect}"
          nil
        end

        def handle_exception(e, _info, payload)
          super(Error.new(e, nil, payload))
        rescue StandardError => e
          info "!!!FAILSAFE!!! #{e.message}"
          Sentry.capture_exception(e)
        end
      end
    end
  end
end
