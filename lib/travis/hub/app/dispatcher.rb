require 'travis/hub/app/queue'
require 'travis/hub/app/solo'

module Travis
  module Hub
    module App
      class Dispatcher < Solo
        attr_accessor :count, :publishers

        def initialize(name, count)
          super(name)
          @count = count.to_i
          @publishers = setup_publishers
        end

        private

          def handle_event(event, payload)
            publisher = publisher_for(payload)
            publisher.publish(payload.merge(worker_count: count), properties: { type: event })
            meter
          end

          def publisher_for(payload)
            id  = ::Job.find(payload.fetch('id')).source_id
            key = queue_for(id % count)
            publishers[key]
          end

          def setup_publishers
            (1..count).inject({}) do |publishers, num|
              name = queue_for(num)
              publishers[name] = Travis::Amqp::Publisher.jobs(name)
              publishers
            end
          end

          def queue_for(num)
            "#{QUEUE}.#{num + 1}"
          end

          def meter
            Metriks.meter("hub.#{name}.delegate.#{key}").mark
          end
      end
    end
  end
end
