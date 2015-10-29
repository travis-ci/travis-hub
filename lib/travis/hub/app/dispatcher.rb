require 'travis/hub/app/queue'
require 'travis/hub/app/solo'

module Travis
  module Hub
    class App
      class Dispatcher < Solo
        attr_accessor :count, :publishers

        def initialize(context, name, options)
          super
          @publishers = setup_publishers
        end

        private

          def handle(type, payload)
            with_active_record do
              id  = ::Job.find(payload.fetch('id')).source_id
              key = queue_for(id % count + 1)
              # puts "Routing #{type} for <Job id=#{payload.fetch('id')}> to #{key}."
              publishers[key].publish(payload.merge(worker_count: count), properties: { type: type })
              meter("hub.#{name}.delegate.#{key}")
            end
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

          def with_active_record(&block)
            ActiveRecord::Base.connection_pool.with_connection(&block)
          end
      end
    end
  end
end
