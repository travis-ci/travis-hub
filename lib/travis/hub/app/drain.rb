require 'sidekiq'
require 'travis/hub/app/queue'

module Travis
  module Hub
    class App
      class Drain < Struct.new(:name, :options)
        def run
          Queue.subscribe(QUEUE, &method(:handle))
        end

        def handle(type, payload)
          publish(type, payload)
          meter(key)
        end

        private

          def publish(type, payload)
            ::Sidekiq::Client.push(
              'queue'   => 'hub',
              'class'   => 'Travis::Hub::Sidekiq::Worker',
              'args'    => [type, payload]
            )
          end

          def meter(key)
            Metrics.meter("hub.#{name}.drain.#{key}")
          end
      end
    end
  end
end
