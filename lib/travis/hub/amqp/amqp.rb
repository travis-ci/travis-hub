require 'amqp'
require 'multi_json'

module Travis
  module Hub
    class Amqp
      class Amqp
        DEFAULTS = {
          :persistent  => true,
          :durable     => true,
          :auto_delete => false
        }

        def subscribe(options, &block)
          queue.subscribe(options, &block)
        end

        def publish(queue, data, options = {})
          data = MultiJson.encode(data) if data.is_a?(Hash)
          options = DEFAULTS.merge(options.merge(:routing_key => queue))
          exchange.publish(data, options)
        end

        protected

          def queue
            @queue ||= channel.queue(REPORTING_KEY, :durable => true, :exclusive => false)
          end

          def exchange
            @exchange ||= AMQP.channel.default_exchange
          end

          def channel
            @channel ||=  AMQP::Channel.new(connection).prefetch(config.prefetch)
          end

          def connection
            @connection ||= AMQP.start(config)
          end
      end
    end
  end
end
