require 'travis/hub/app/queue'
require 'travis/hub/app/solo'

module Travis
  module Hub
    module App
      class Dispatcher < Solo
        attr_accessor :count, :publishers

        def initialize(name, options)
          super
          @publishers = setup_publishers
        end

        private

          def handle(type, payload)
            id  = ::Job.find(payload.fetch('id')).source_id
            key = queue_for(id % count + 1)
            # puts "Routing #{type} for <Job id=#{payload.fetch('id')}> to #{key}."
            publishers[key].publish(payload.merge(worker_count: count), properties: { type: type })
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
            Metrics.meter("hub.#{name}.delegate.#{key}")
          end
      end
    end
  end
end
