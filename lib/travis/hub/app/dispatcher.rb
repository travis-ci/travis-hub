require 'travis/hub/app/queue'
require 'travis/hub/app/solo'

module Travis
  module Hub
    module App
      class Dispatcher < Solo
        attr_accessor :count, :publishers

        def initialize(name, count)
          super(name)
          @count = count
          @publishers = setup_publishers
        end

        private

          def handle_event(event, payload)
            id  = ::Job.find(payload.fetch('id')).source_id
            key = queue_for(id % count + 1)
            publishers[key].publish(payload.merge(worker_count: count), properties: { type: event })
            meter(key)
          end

          def setup_publishers
            (1..count).inject({}) do |publishers, num|
              name = queue_for(num)
              publishers.merge(name => Travis::Amqp::Publisher.jobs(name))
            end
          end

          def queue_for(num)
            "#{QUEUE}.#{num}"
          end

          def meter(key)
            Metriks.meter("hub.#{name}.delegate.#{key}").mark
          end
      end
    end
  end
end
