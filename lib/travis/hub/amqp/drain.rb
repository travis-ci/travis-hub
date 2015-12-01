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
          info "Draining #{event} for id=#{payload['id']} to sidekiq=hub"
          publish(event, payload)
          meter('hub.drain')
        end

        private

          def publish(event, payload)
            ::Sidekiq::Client.push(
              'queue'   => 'hub',
              'class'   => 'Travis::Hub::Sidekiq::Worker',
              'args'    => [event, payload]
            )
          end
      end
    end
  end
end
