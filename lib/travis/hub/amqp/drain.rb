require 'sidekiq'
require 'travis/hub/amqp/queue'
require 'travis/hub/helper/context'

module Travis
  module Hub
    class Amqp
      class Drain < Struct.new(:context, :name, :options)
        include Helper::Context

        def run
          Queue.new(context, config.queue, &method(:handle)).subscribe
        end

        def handle(event, payload)
          publish(event, payload)
          meter(key)
        end

        private

          def publish(event, payload)
            ::Sidekiq::Client.push(
              'queue'   => 'hub',
              'class'   => 'Travis::Hub::Sidekiq::Worker',
              'args'    => [event, payload]
            )
          end

          def meter(key)
            super("hub.#{name}.drain.#{key}")
          end
      end
    end
  end
end
