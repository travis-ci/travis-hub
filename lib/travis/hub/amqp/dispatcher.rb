require 'travis/hub/amqp/queue'
require 'travis/hub/amqp/solo'
require 'travis/hub/helper/context'
require 'travis/hub/support/reroute'

module Travis
  module Hub
    class Amqp
      class Dispatcher
        include Helper::Context

        attr_reader :context, :count, :publishers

        def initialize(context, _, options)
          @context = context
          @count = options[:count] || 1
          @publishers = {}
        end

        private

          def handle(event, payload)
            with_active_record do
              job = ::Job.find(payload.fetch('id'))
              # key = reroute?(job) ? :next : job.source_id % count + 1
              key = job.source_id % count + 1
              puts "Routing #{event} for <Job id=#{job.id}> to #{queue_for(key)}."
              publish(key, event, payload)
            end
          end

          def publish(key, event, payload)
            publisher = publisher(queue_for(key))
            publisher.publish(payload.merge(worker_count: count), properties: { type: event })
            meter("hub.dispatcher.delegate.#{key}")
          end

          # def reroute?(job)
          #   Reroute.new(:hub_next, id: job.id, owner_name: job.repository.owner_name).reroute?
          # end

          def publisher(name)
            publishers[name] ||= Travis::Amqp::Publisher.jobs(name)
          end

          def queue_for(num)
            "#{queue}.#{num}"
          end

          def with_active_record(&block)
            Job.connection_pool.with_connection(&block)
          end
      end
    end
  end
end
