require 'travis/hub/app/queue'
require 'travis/hub/app/solo'
require 'travis/hub/support/reroute'

module Travis
  module Hub
    class App
      class Dispatcher < Solo
        attr_reader :publishers

        def initialize(*)
          super
          @publishers = {}
        end

        private

          def handle(type, payload)
            with_active_record do
              job = ::Job.find(payload.fetch('id'))
              key = reroute?(job) ? :next : job.source_id % count + 1
              puts "Routing #{type} for <Job id=#{job.id}> to #{queue_for(key)}."
              publish(key, type, payload)
            end
          end

          def publish(key, type, payload)
            publisher = publisher(queue_for(key))
            publisher.publish(payload.merge(worker_count: count), properties: { type: type })
            meter("hub.#{name}.delegate.#{key}")
          end

          def reroute?(job)
            Reroute.new(:hub_next, id: job.id, owner_name: job.repository.owner_name).run
          end

          def publisher(name)
            publishers[name] ||= Travis::Amqp::Publisher.jobs(name)
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
